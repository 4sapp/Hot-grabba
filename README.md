# El antifake de USSL se bypassea. Probado en Windows real.

> Qué chequea el staff antes de un oficial, cómo se pasa el check completo, qué se midió en una máquina real y por qué el método es débil.
>
> Probado el **2026-11-15** en una VM de **Windows Server 2022 (10.0.20348)**.

---

## ![](https://app.devin.ai/attachments/ffe90d9f-9908-489e-a5c1-59a1f3dad599/alert-24.svg) Veredicto

Sí, se bypassea. Lo comprobamos en una VM real.

El antifake entero se resume en una idea: si la lista de procesos y la pantalla no muestran nada raro, la PC está limpia. El problema es que un cheat no necesita ser un proceso propio. Puede vivir dentro de un proceso legítimo de Windows, y ni `tasklist`, ni el Task Manager, ni la captura de pantalla lo ven.

Corrimos el equivalente del cheat dentro de `rundll32.exe`, un proceso firmado por Microsoft. En `tasklist /fo table`, el comando exacto que pide el staff, solo aparece `rundll32.exe`. Nombre normal, firma válida, cero banderas. El check pasa en verde con el módulo activo adentro.

---

## ![](https://app.devin.ai/attachments/be30bda7-5914-4286-b28e-4fa9eee58ebe/book-24.svg) 1. Qué es el antifake de USSL

La liga corre una revisión rápida antes y después de cada oficial de Roblox. El staff le pide al jugador esto:

1. **SHIFT+F5** dentro del juego para mostrar los FPS, con Roblox en ventana chica.
2. **CTRL+SHIFT+ESC** para abrir el Task Manager y mostrar las apps en segundo plano.
3. **WIN+R** y pegar `%localappdata%\Roblox\GlobalBasicSettings_13.xml` para abrir la carpeta de Roblox.
4. Abrir `cmd` y correr `tasklist /fo table` para listar toda la actividad de la PC.
5. Tomar una captura completa con Discord, Roblox, la carpeta y los íconos ocultos de la bandeja visibles, y mandarla al canal del staff.

Regla extra: el jugador no puede salir del juego durante la revisión. Si rejoin, repite todo el procedimiento con un staff mirando.

Para el que no sabe: un proceso es cada programa corriendo, como `chrome.exe` o `Discord.exe`. La idea del staff es que si el cheat corre, debería verse en la lista. El error técnico es que un cheat no tiene por qué ser un proceso propio.

---

## ![](https://app.devin.ai/attachments/a5915cf9-f1f5-4246-8216-b3236ee5f20f/unlock-24.svg) 2. Cómo se bypassea

### El error de fondo: mirar procesos, no módulos

Un cheat puede existir de dos formas.

La primera es un `.exe` propio. Eso es lo que el staff espera ver, y aparece en tasklist.

La segunda es una DLL cargada dentro de un proceso legítimo. Eso no aparece en tasklist. El comando lista procesos, no los módulos que cada proceso cargó. Es así como funcionan los executors de Roblox de verdad: inyectan su código dentro de `RobloxPlayerBeta.exe` o de un proceso de Windows.

Lo mismo con el Task Manager y la bandeja. Muestran procesos y apps con ventana o ícono, no las DLLs que cada uno lleva adentro.

![El cheat vive dentro del proceso](https://app.devin.ai/attachments/baf39f6f-fe3a-4230-bc6c-0b5e0e41404d/dentro-del-proceso.svg)

### El método probado: rundll32, el LOLBin clásico

Windows trae `rundll32.exe`, un binario firmado por Microsoft cuyo único trabajo es cargar una DLL y ejecutar una función de ella. Es la técnica favorita para correr código sin proceso propio:

```text
rundll32.exe C:\cualquier\ruta\CheatCore.dll,EntryPoint
```

En tasklist aparece `rundll32.exe`. Nombre de Windows, firma de Microsoft, nada raro. La DLL del cheat vive adentro, invisible para el check.

![Flujo del bypass](https://app.devin.ai/attachments/80845d34-0ced-4072-84bb-ed422a37c0d1/flujo-bypass.svg)

### La variante más barata: renombrar el ejecutable

Un `.exe` llamado `RuntimeBroker.exe` o `svchost.exe` también se ve normal en la lista. En la sección 3.4 está cómo se detecta igual: el nombre es lo único que copiaron. La ruta, los metadatos y la firma no mienten.

### La variante que no necesita nada corriendo

El procedimiento completo está publicado. El jugador sabe qué van a mirar y cuándo. Entonces la secuencia más simple es descargar el cheat antes del oficial, jugar, cerrarlo justo antes de la revisión y tomar la captura limpio. La regla de "no puedes salir del juego" no impide haber cargado el cheat antes de entrar.

---

## ![](https://app.devin.ai/attachments/8d14af0e-e7c7-432b-9cdc-87747cada6f3/beaker-24.svg) 3. La prueba real en Windows

Lo montamos en la VM. Como cheat usamos una copia de `shell32.dll` renombrada a `CheatCore.dll`. Bytes idénticos al original, firma de Microsoft válida. El contenido no importa para la demo. Lo que importa es dónde vive.

### 3.1 El bypass corriendo

```text
"C:\Windows\System32\rundll32.exe" C:\antifake-poc\CheatCore.dll,OpenAs_RunDLL ...
```

`rundll32.exe` con PID 5652 quedó vivo con `CheatCore.dll` mapeada dentro.

Detalle honesto: la primera variante probada, `Control_RunDLL`, cargó la DLL pero el proceso murió al instante. La técnica necesita un punto de entrada que mantenga vivo al proceso. Con `OpenAs_RunDLL`, que abre un diálogo bloqueante, quedó corriendo.

### 3.2 Lo que ve el staff: `tasklist /fo table`

Output real mientras el cheat estaba activo. Extracto del listado completo de unos 140 procesos:

```text
Image Name                     PID Session Name        Session#    Mem Usage
========================= ======== ================ =========== ============
RuntimeBroker.exe             4864 Console                    1     14,524 K
RuntimeBroker.exe             3576 Console                    1     22,700 K
RuntimeBroker.exe             5528 Console                    1     15,056 K
chrome.exe                    3888 Console                    1     71,192 K
powershell.exe                6248 Console                    1    101,196 K
rundll32.exe                  5652 Console                    1     12,060 K   <- el cheat vive aqui
OpenWith.exe                  2832 Console                    1     35,416 K
tasklist.exe                  9060 Console                    1      8,968 K
```

Una fila `rundll32.exe`, nombre firmado por Microsoft. En el tasklist de un jugador esa línea no levanta ni una ceja. Check pasado.

### 3.3 Lo que ve el staff que sabe revisar

Tres comandos. Los tres lo cachan al instante.

Primero, el inventario de módulos:

```text
> tasklist /m CheatCore.dll

Image Name                     PID Modules
========================= ======== ============================================
rundll32.exe                  5652 CheatCore.dll
```

Segundo, la línea de comandos completa del proceso:

```text
> Get-CimInstance Win32_Process -Filter "Name='rundll32.exe'" | Select ProcessId,CommandLine

ProcessId CommandLine
--------- -----------
     5652 "C:\Windows\System32\rundll32.exe" C:\antifake-poc\CheatCore.dll,OpenAs_RunDLL ...
```

Ahí está escrito literalmente qué DLL cargó. Un rundll32 cargando algo fuera de `C:\Windows` es para investigar.

Tercero, los módulos cargados desde rutas raras:

```text
> Get-Process rundll32 | Select -Expand Modules | ? {$_.FileName -notlike 'C:\Windows\*'}

ModuleName    FileName
----------    --------
CheatCore.dll C:\antifake-poc\CheatCore.dll
```

### 3.4 La trampa del renombrado, también probada

Se copió el ejecutable de prueba con el nombre neutro `IdentitySample.exe` y se corrió. En tasklist solo se ve un nombre más. Pero sin abrir nada ya delata tres cosas:

- El metadato `OriginalFilename` seguía diciendo `ModuleHost.exe`. Renombrar el archivo no edita sus metadatos.
- Corría desde `C:\antifake-poc\`, no desde `C:\Windows\System32`.
- Firma `NotSigned`. Los RuntimeBroker reales de la misma VM viven todos en System32 con firma `Valid`:

```text
> Get-Process RuntimeBroker | Select Name,Path
RuntimeBroker C:\Windows\System32\RuntimeBroker.exe
RuntimeBroker C:\Windows\System32\RuntimeBroker.exe
RuntimeBroker C:\Windows\System32\RuntimeBroker.exe
```

Un "RuntimeBroker" corriendo desde otra carpeta y sin firma no es RuntimeBroker.

### 3.5 El dato que empeora todo para el staff

También se cargó una DLL .NET de prueba. Resultado: `tasklist /m` ni siquiera la lista. Las APIs nativas de inventario no ven assemblies administrados. Un cheat escrito en .NET dentro de un proceso no aparece ni en la lista de procesos ni en la lista básica de módulos. Para verlo hacen falta herramientas CLR de verdad, muy por encima de un `tasklist`.

---

## ![](https://app.devin.ai/attachments/741ed9ce-d656-4dbb-b874-9bc0da21ae7d/shield-check-24.svg) 4. El fix para el staff

Si la liga quiere un check que de verdad complique al cheater, esto es lo mínimo. Todo es read-only, no toca nada:

```powershell
# Modulos cargados por proceso. El cheat como DLL aparece aqui.
tasklist /m
tasklist /m <nombre-sospechoso>.dll

# Lineas de comando completas. Delata rundll32, regsvr32 y powershell raros.
Get-CimInstance Win32_Process | Select Name,ProcessId,CommandLine | Format-List

# Modulos cargados desde fuera de C:\Windows
Get-Process | Select -Expand Modules | ? {$_.FileName -notlike 'C:\Windows\*'}

# Procesos con nombre de sistema pero ruta rara
Get-Process | Select Name,Path | ? {$_.Path -notlike 'C:\Windows\*'}

# Firma y metadatos del ejecutable
Get-AuthenticodeSignature <ruta>
(Get-Item <ruta>).VersionInfo.OriginalFilename

# Lo que corrio HOY aunque ya no este corriendo
Get-ChildItem C:\Windows\Prefetch\*.pf | Sort LastWriteTime -Desc | Select -First 30
```

Tres cambios de fondo además de los comandos:

- Mirar dentro de `RobloxPlayerBeta.exe`, no solo que existe. Process Explorer de Sysinternals muestra las DLLs del proceso.
- Screenshare en vivo en vez de captura estática. Una foto se toma después de limpiar. Un video en vivo se ve mientras pasa.
- Historial en vez de presente. Prefetch, descargas recientes y USN journal dicen qué se ejecutó hoy y a qué hora, no solo qué corre ahora.

---

## ![](https://app.devin.ai/attachments/c1eaa700-0eb2-46d5-a8cf-b3909ab60768/eye-24.svg) 5. Crítica al antifake de USSL

### Mide procesos, no código

La premisa del check es "cheat = proceso visible". Los cheats serios hace años viven como DLL dentro de procesos legítimos. Lo demostramos metiendo `CheatCore.dll` dentro de `rundll32.exe`, el nombre más limpio que existe en Windows. `tasklist` está diseñado para no mostrar eso.

### Es un ritual de apariencias

Carpeta de Roblox abierta, íconos de bandeja, ventana chica, captura bonita. Todo eso mide qué tan ordenado dejó el escritorio el jugador. No mide qué corre en la PC. Un cheat bien hecho ni siquiera toca la carpeta de Roblox.

### Es estático y está avisado

El jugador conoce el guion completo por adelantado: qué abrir, qué mostrar, qué capturar. Preparar una PC que pase es seguir el mismo guion pero limpiando antes. La regla de no salir del juego cierra solo la vía más tonta. No cierra la carga previa del cheat, el cheat en DLL ni el cheat externo.

### Una captura no prueba nada

Un screenshot se produce después de ordenar el estado. Y hay cheats que nunca generan algo visible en esa lista: macros en el firmware del mouse, autoclickers del software del fabricante como Razer Synapse o Logitech G-Hub, o código corriendo en otra PC.

![Check debil vs check fuerte](https://app.devin.ai/attachments/b3508520-0219-4624-a10f-887998e720f9/debil-vs-fuerte.svg)

Veredicto final: el antifake es cosmético. Sirve para que el staff parezca que revisa y para cachar al jugador que deja su `cheat.exe` abierto en la bandeja. Contra alguien que sabe lo que hace, `tasklist /fo table` es decoración. La versión que de verdad complica mira módulos, líneas de comando, rutas, firmas e historial. Todo eso está en `detect.ps1`.

---

## ![](https://app.devin.ai/attachments/14fb60f1-2bfe-4513-80df-74a09b75926a/person-24.svg) Contacto

[![Discord Presence](https://lanyard.cnrad.dev/api/1038423018139037738)](https://discord.com/users/1038423018139037738)

[![Discord](https://img.shields.io/badge/Discord-jujuda3-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.com/users/1038423018139037738)
