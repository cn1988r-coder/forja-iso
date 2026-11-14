#!/usr/bin/env python3
"""Forja Local: authenticated local ISO builder."""
import hashlib, json, os, platform, re, secrets, shutil, subprocess, threading, time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import tkinter as tk
from tkinter import messagebox

APP_ORIGIN = "https://forja-de-iso-lfeex7.v2.appdeploy.ai"
HOST, PORT, VERSION = "127.0.0.1", 18765, "0.4.0"
CONFIG = Path.home() / ".config/forja-agent"
TOKEN_FILE, PROFILE_FILE = CONFIG / "token.json", CONFIG / "profile.json"
WORK = Path.home() / "Forja-ISO"
PAIR_CODE = secrets.token_hex(3).upper()
ALLOWED = {"firefox", "ferdium", "timeshift", "bluetooth", "printing", "audio"}
LOCK = threading.Lock()
STATE = {"status":"idle","progress":0,"message":"Aguardando compilação.","log":[],"iso_name":"","sha256":"","warnings":[],"started_at":None,"finished_at":None}

def token_saved():
    try: return json.loads(TOKEN_FILE.read_text()).get("token","")
    except (OSError, ValueError, AttributeError): return ""

def os_info():
    data = {}
    try:
        for line in Path("/etc/os-release").read_text().splitlines():
            if "=" in line:
                k,v=line.split("=",1); data[k]=v.strip().strip('"')
    except OSError: pass
    return data

def mem_gb():
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            if line.startswith("MemTotal:"): return round(int(line.split()[1])/1024/1024,1)
    except (OSError,ValueError,IndexError): pass
    return 0

def free_gb(): return round(shutil.disk_usage(Path.home()).free/1024**3,1)

def capabilities():
    distro=os_info().get("ID","").lower()
    arch=platform.machine()=="x86_64"
    checks={
      "x86_64":arch,"memory_8gb":mem_gb()>=8,"disk_35gb":free_gb()>=35,
      "git":shutil.which("git") is not None,
      "archiso":distro=="arch" and shutil.which("mkarchiso") is not None and Path("/usr/share/archiso/configs/releng").is_dir(),
      "manjaro_buildiso":distro=="manjaro" and shutil.which("buildiso") is not None and shutil.which("pkexec") is not None
    }
    supported=[]
    if distro=="arch" and all([checks["x86_64"],checks["memory_8gb"],checks["disk_35gb"],checks["archiso"]]): supported.append("Arch Linux")
    if distro=="manjaro" and all([checks["x86_64"],checks["memory_8gb"],checks["disk_35gb"],checks["git"],checks["manjaro_buildiso"]]): supported.append("Manjaro")
    msg=("Compilador disponível para: "+", ".join(supported)) if supported else "Host sem os requisitos. Arch exige archiso; Manjaro exige buildiso e pkexec. Ambos exigem x86_64, 8 GB RAM e 35 GB livres."
    return {"distribution":os_info().get("PRETTY_NAME",distro or "Desconhecido"),"distribution_id":distro,"architecture":platform.machine(),"memory_gb":mem_gb(),"free_disk_gb":free_gb(),"cpu_threads":os.cpu_count() or 0,"checks":checks,"supported_distributions":supported,"builder_ready":bool(supported),"builder_message":msg}

def log(message):
    line=str(message).rstrip()
    if line:
        with LOCK:
            STATE["log"].append(line[-1200:]); STATE["log"]=STATE["log"][-160:]; STATE["message"]=line[-240:]

def run(command,cwd=None,progress=10):
    log("$ "+" ".join(map(str,command)))
    p=subprocess.Popen(command,cwd=str(cwd) if cwd else None,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
    for line in p.stdout:
        log(line)
        with LOCK: STATE["progress"]=max(STATE["progress"],progress)
    code=p.wait()
    if code: raise RuntimeError("Comando falhou com código "+str(code)+": "+" ".join(command[:3]))

def validate(profile):
    if not isinstance(profile,dict): raise ValueError("Perfil inválido.")
    if profile.get("distribution") not in {"Arch Linux","Manjaro"}: raise ValueError("Distribuição não suportada.")
    if profile.get("architecture")!="x86_64" or profile.get("desktop")!="MATE" or profile.get("displayManager")!="LightDM" or profile.get("windowManager")!="Marco": raise ValueError("Perfil atual exige x86_64, MATE, LightDM e Marco.")
    if profile.get("kernel") not in {"Padrão","LTS"}: raise ValueError("Kernel inválido.")
    if not re.fullmatch(r"[a-zA-Z0-9-]{1,32}",str(profile.get("hostname","forja-mate"))): raise ValueError("Nome do sistema inválido.")
    packages=profile.get("packages",[])
    if not isinstance(packages,list) or len(packages)>len(ALLOWED) or any(not isinstance(x,str) or x not in ALLOWED for x in packages): raise ValueError("Lista de programas inválida.")
    return profile

def validate_iso(folder):
    files=sorted(Path(folder).glob("*.iso"),key=lambda p:p.stat().st_mtime,reverse=True)
    if not files: raise RuntimeError("O compilador terminou sem produzir ISO.")
    iso=files[0]
    if iso.stat().st_size<100*1024*1024: raise RuntimeError("Arquivo ISO inválido ou incompleto. Download bloqueado.")
    digest=hashlib.sha256()
    with iso.open("rb") as f:
        for block in iter(lambda:f.read(4*1024*1024),b""): digest.update(block)
    sha=digest.hexdigest()
    iso.with_suffix(iso.suffix+".sha256").write_text(sha+"  "+iso.name+"\n")
    log("ISO validada: "+iso.name+" | SHA-256 "+sha)
    return iso,sha

def build_arch(profile):
    if os_info().get("ID")!="arch": raise RuntimeError("Para criar ISO Arch, execute o agente em Arch Linux.")
    base=Path("/usr/share/archiso/configs/releng")
    if not shutil.which("mkarchiso") or not (base/"profiledef.sh").is_file(): raise RuntimeError("Instale archiso: sudo pacman -S archiso.")
    WORK.mkdir(parents=True,exist_ok=True)
    prof=WORK/"profile-arch-mate"; out=WORK/"output"; work=WORK/"work"
    if prof.exists(): shutil.rmtree(prof)
    shutil.copytree(base,prof,symlinks=True); out.mkdir(exist_ok=True)
    pkgfile=prof/"packages.x86_64"
    pkgs=[x.strip() for x in pkgfile.read_text().splitlines() if x.strip() and not x.lstrip().startswith("#")]
    kernel="linux-lts" if profile["kernel"]=="LTS" else "linux"
    pkgs=[x for x in pkgs if x not in {"linux","linux-lts"}]
    pkgs += [kernel,"linux-firmware","mate","mate-extra","xorg-server","lightdm","lightdm-gtk-greeter","networkmanager","network-manager-applet","firefox","xdg-user-dirs"]
    selected=set(profile.get("packages",[]))
    if "timeshift" in selected: pkgs.append("timeshift")
    if "bluetooth" in selected: pkgs += ["bluez","bluez-utils","blueman"]
    if "printing" in selected: pkgs += ["cups","system-config-printer"]
    if "audio" in selected: pkgs += ["pipewire","pipewire-alsa","pipewire-pulse","wireplumber"]
    pkgfile.write_text("\n".join(dict.fromkeys(pkgs))+"\n")
    overlay=prof/"airootfs"; wants=overlay/"etc/systemd/system/multi-user.target.wants"; wants.mkdir(parents=True,exist_ok=True)
    services=["lightdm.service","NetworkManager.service"]
    if "bluetooth" in selected: services.append("bluetooth.service")
    if "printing" in selected: services.append("cups.service")
    for service in services:
        link=wants/service
        if link.exists() or link.is_symlink(): link.unlink()
        link.symlink_to("/usr/lib/systemd/system/"+service)
    conf=overlay/"etc/lightdm/lightdm.conf.d/50-forja.conf"; conf.parent.mkdir(parents=True,exist_ok=True)
    conf.write_text("[Seat:*]\ngreeter-session=lightdm-gtk-greeter\n")
    host=overlay/"etc/hostname"; host.parent.mkdir(parents=True,exist_ok=True); host.write_text(profile["hostname"]+"\n")
    with LOCK: STATE["warnings"]=["Ferdium foi ignorado: é pacote AUR e ainda não faz parte desta etapa do instalador."] if "ferdium" in selected else []
    log("Preparando perfil Arch MATE com archiso.")
    run(["mkarchiso","-v","-w",str(work),"-o",str(out),str(prof)],progress=20)
    return validate_iso(out)

def build_manjaro(profile):
    if os_info().get("ID")!="manjaro": raise RuntimeError("Para criar ISO Manjaro, execute o agente em Manjaro.")
    if not shutil.which("buildiso") or not shutil.which("pkexec"): raise RuntimeError("Instale manjaro-tools-iso e polkit.")
    WORK.mkdir(parents=True,exist_ok=True); profiles=WORK/"iso-profiles"
    if not (profiles/".git").is_dir():
        run(["git","clone","--depth","1","https://gitlab.manjaro.org/profiles-and-settings/iso-profiles.git",str(profiles)],progress=8)
    source=profiles/"manjaro/xfce"; target=profiles/"manjaro/mate-custom"
    if not (source/"Packages-Desktop").is_file() or not (source/"profile.conf").is_file(): raise RuntimeError("Perfil XFCE oficial não contém a estrutura esperada.")
    if target.exists(): shutil.rmtree(target)
    shutil.copytree(source,target,symlinks=True)
    pkg=target/"Packages-Desktop"; lines=pkg.read_text().splitlines()
    remove=re.compile(r"(xfce|thunar|ristretto|mousepad|parole|orage|catfish|xfburn)",re.I)
    lines=[line for line in lines if not remove.search(line)]
    lines += ["mate","mate-extra","lightdm","lightdm-gtk-greeter","network-manager-applet"]
    selected=set(profile.get("packages",[]))
    if "bluetooth" in selected: lines += ["bluez","bluez-utils","blueman"]
    if "printing" in selected: lines += ["cups","system-config-printer"]
    if "audio" in selected: lines += ["pipewire","pipewire-alsa","pipewire-pulse","wireplumber"]
    if "timeshift" in selected: lines.append("timeshift")
    pkg.write_text("\n".join(dict.fromkeys(lines))+"\n")
    conf=target/"profile.conf"; text=conf.read_text()
    text=re.sub(r"^#?displaymanager=.*$",'displaymanager="lightdm"',text,flags=re.M) if re.search(r"^#?displaymanager=",text,re.M) else text+'\ndisplaymanager="lightdm"\n'
    conf.write_text(text)
    out=WORK/"manjaro-output"; chroots=WORK/"manjaro-chroots"; out.mkdir(exist_ok=True); chroots.mkdir(exist_ok=True)
    with LOCK: STATE["warnings"]=["Ferdium foi ignorado: pacote AUR ainda não integrado."] if "ferdium" in selected else []
    log("Preparando perfil MATE baseado no perfil XFCE oficial do Manjaro.")
    run(["pkexec","/usr/bin/buildiso","-p","mate-custom","-b","stable","-f","-r",str(chroots),"-t",str(out)],cwd=profiles,progress=20)
    return validate_iso(out)

def worker(profile):
    try:
        with LOCK: STATE.update(status="running",progress=2,message="Iniciando motor de compilação.",log=[],iso_name="",sha256="",started_at=time.time(),finished_at=None,warnings=[])
        caps=capabilities()
        if profile["distribution"] not in caps["supported_distributions"]: raise RuntimeError(caps["builder_message"]+" Base selecionada: "+profile["distribution"]+".")
        iso,sha=build_arch(profile) if profile["distribution"]=="Arch Linux" else build_manjaro(profile)
        with LOCK: STATE.update(status="completed",progress=100,message="ISO concluída e validada.",iso_name=iso.name,sha256=sha,finished_at=time.time())
    except Exception as exc:
        log("ERRO: "+str(exc))
        with LOCK: STATE.update(status="failed",progress=0,message=str(exc),finished_at=time.time())

class Handler(BaseHTTPRequestHandler):
    def log_message(self,*_): pass
    def cors(self):
        if self.headers.get("Origin","")!=APP_ORIGIN: return False
        self.send_header("Access-Control-Allow-Origin",APP_ORIGIN); self.send_header("Vary","Origin")
        self.send_header("Access-Control-Allow-Methods","GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers","Content-Type, X-Forja-Token")
        self.send_header("Access-Control-Allow-Private-Network","true"); return True
    def reply(self,status,data):
        self.send_response(status); allowed=self.cors()
        self.send_header("Content-Type","application/json; charset=utf-8"); self.send_header("Cache-Control","no-store")
        if not allowed: self.send_header("Access-Control-Allow-Origin","null")
        self.end_headers(); self.wfile.write(json.dumps(data,ensure_ascii=False).encode())
    def authorized(self):
        saved=token_saved(); given=self.headers.get("X-Forja-Token","")
        return bool(saved and secrets.compare_digest(saved,given))
    def do_OPTIONS(self):
        if self.headers.get("Origin","")!=APP_ORIGIN: self.send_error(403); return
        self.send_response(204); self.cors(); self.end_headers()
    def do_GET(self):
        if self.path=="/status":
            info=capabilities(); saved=token_saved(); given=self.headers.get("X-Forja-Token","")
            self.reply(200,{"agent":"Forja Local","version":VERSION,"available":True,"paired":bool(saved),"authorized":bool(saved and secrets.compare_digest(saved,given)),"profile_saved":PROFILE_FILE.exists(),"build_enabled":bool(info["supported_distributions"]),"builder":info}); return
        if self.path=="/preflight":
            if not self.authorized(): self.reply(401,{"error":"unauthorized"}); return
            self.reply(200,capabilities()); return
        if self.path=="/build/status":
            if not self.authorized(): self.reply(401,{"error":"unauthorized"}); return
            with LOCK: data=dict(STATE); data["log"]=STATE["log"][-100:]; data["warnings"]=list(STATE["warnings"])
            self.reply(200,data); return
        if self.path=="/download":
            if not self.authorized(): self.reply(401,{"error":"unauthorized"}); return
            with LOCK: name=STATE.get("iso_name"); status=STATE.get("status")
            iso=None
            if status=="completed" and name:
                for folder in (WORK/"output",WORK/"manjaro-output"):
                    candidate=folder/name
                    if candidate.is_file(): iso=candidate; break
            if not iso: self.reply(404,{"error":"iso_not_available"}); return
            self.send_response(200); self.cors(); self.send_header("Content-Type","application/x-iso9660-image")
            self.send_header("Content-Length",str(iso.stat().st_size)); self.send_header("Content-Disposition",'attachment; filename="'+iso.name.replace('"',"")+'"')
            self.send_header("Cache-Control","no-store"); self.end_headers()
            with iso.open("rb") as stream: shutil.copyfileobj(stream,self.wfile,1024*1024)
            return
        self.reply(404,{"error":"not_found"})
    def do_POST(self):
        global PAIR_CODE
        if self.headers.get("Origin","")!=APP_ORIGIN: self.reply(403,{"error":"origin_not_allowed"}); return
        try:
            length=int(self.headers.get("Content-Length","0"))
            if length<1 or length>16384: self.reply(400,{"error":"invalid_body_size"}); return
            body=json.loads(self.rfile.read(length))
        except (ValueError,json.JSONDecodeError): self.reply(400,{"error":"invalid_json"}); return
        if self.path=="/pair":
            if not PAIR_CODE or not isinstance(body,dict) or not secrets.compare_digest(str(body.get("code","")),PAIR_CODE): self.reply(403,{"error":"invalid_pair_code"}); return
            CONFIG.mkdir(parents=True,exist_ok=True); value=secrets.token_urlsafe(32); temp=TOKEN_FILE.with_suffix(".tmp")
            temp.write_text(json.dumps({"token":value})); os.chmod(temp,0o600); temp.replace(TOKEN_FILE); PAIR_CODE=""
            self.reply(200,{"paired":True,"token":value}); return
        if not self.authorized(): self.reply(401,{"error":"unauthorized"}); return
        if self.path=="/profile":
            try: validate(body)
            except ValueError as exc: self.reply(422,{"error":str(exc)}); return
            CONFIG.mkdir(parents=True,exist_ok=True); temp=PROFILE_FILE.with_suffix(".tmp")
            temp.write_text(json.dumps(body,indent=2,ensure_ascii=False)); os.chmod(temp,0o600); temp.replace(PROFILE_FILE)
            self.reply(200,{"saved":True,"build_enabled":True}); return
        if self.path=="/build":
            try: profile=validate(body)
            except ValueError as exc: self.reply(422,{"error":str(exc)}); return
            caps=capabilities()
            if profile["distribution"] not in caps["supported_distributions"]: self.reply(409,{"error":caps["builder_message"],"builder":caps}); return
            with LOCK:
                if STATE["status"] in {"queued","running"}: self.reply(409,{"error":"Já existe uma compilação em andamento."}); return
                STATE.update(status="queued",progress=1,message="Compilação adicionada à fila.",log=[],iso_name="",sha256="",warnings=[])
            CONFIG.mkdir(parents=True,exist_ok=True); PROFILE_FILE.write_text(json.dumps(profile,indent=2,ensure_ascii=False))
            threading.Thread(target=worker,args=(profile,),daemon=True).start()
            self.reply(202,{"started":True,"status":"queued"}); return
        self.reply(404,{"error":"not_found"})

class AgentApp:
    def __init__(self,root):
        self.root=root; root.title("Forja Local"); root.geometry("480x310"); root.resizable(False,False); root.configure(bg="#0b1220")
        tk.Label(root,text="FORJA LOCAL",fg="#8bd4ff",bg="#0b1220",font=("Sans",16,"bold")).pack(pady=(20,6))
        tk.Label(root,text="Código de pareamento (uso único)",fg="#cbd5e1",bg="#0b1220",font=("Sans",10)).pack()
        tk.Label(root,text=PAIR_CODE,fg="#ffffff",bg="#17263b",font=("Monospace",24,"bold"),padx=18,pady=10).pack(pady=8)
        self.status=tk.Label(root,text="Iniciando serviço local...",fg="#f6c177",bg="#0b1220",font=("Sans",10)); self.status.pack(pady=4)
        tk.Label(root,text="A ISO é compilada e armazenada neste computador.",fg="#8392a8",bg="#0b1220",font=("Sans",8)).pack(pady=8)
        self.server=HTTPServer((HOST,PORT),Handler); threading.Thread(target=self.server.serve_forever,daemon=True).start()
        self.status.config(text=f"Serviço ativo em {HOST}:{PORT}",fg="#8be0b0"); root.protocol("WM_DELETE_WINDOW",self.close)
    def close(self): self.server.shutdown(); self.server.server_close(); self.root.destroy()

if __name__=="__main__":
    try:
        window=tk.Tk(); AgentApp(window); window.mainloop()
    except OSError as exc:
        fallback=tk.Tk(); fallback.withdraw(); messagebox.showerror("Forja Local",f"Não foi possível iniciar o serviço: {exc}"); fallback.destroy()
