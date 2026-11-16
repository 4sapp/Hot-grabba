# Hot-grabba

Métodos de revisión de anti-cheat (SS, screenshare) puestos a prueba en una VM de Windows real.

Cada reporte trae el contexto para el que no sabe del tema, el bypass ejecutado con outputs reales, y el fix que el staff debería usar en su lugar.

---

## Métodos

### [Antifake de USSL (Roblox)](antifake-ussl/)

El staff pide `tasklist /fo table`, Task Manager, la carpeta de Roblox y una captura de pantalla completa.

Bypass probado: el cheat corre como DLL dentro de `rundll32.exe`, un proceso firmado por Microsoft. La lista de procesos solo muestra `rundll32.exe` y el check pasa en verde con el módulo activo adentro.

Fix: `tasklist /m`, línea de comandos de cada proceso y módulos fuera de `C:\Windows`. Incluye `detect.ps1` e `Injector.cs`.

### [Check de servicios detenidos](servicios-ss/)

La regla: si alguno de 8 servicios de Windows aparece `Stopped` durante la SS, se considera "logs detenidos".

Bypass probado: detener los servicios, borrar prefetch y artefactos, y restaurar todo con el mismo script de reparación del staff. El ciclo completo dura unos 2 segundos y el check vuelve a verde. Bonus: una PC limpia de fábrica ya falla el check en 5 de 8 servicios.

Fix: eventos 7036/7040, hora de arranque del proceso del servicio vs encendido del PC, continuidad de logs y prefetch. Incluye `detect.ps1` y `bypass.ps1`.

### [Voyage.ac descompilado](voyage-ac/)

Análisis completo del scanner comercial de SS (Nuitka, Python compilado): qué hay dentro, cómo se comporta en vivo y sus 46 checks de detección.

Resultado: todos los bypasses de los dos reportes anteriores mueren aquí — lee historial (BAM, USN, ShimCache), detecta la propia limpieza y cubre LOLBins, .NET y exes renombrados. Sus gaps reales: sin admin queda a medias, marca algunas PCs limpias con flags low y decide un humano.

---

Los dos primeros métodos cometen el mismo error: miran el estado presente y no el historial. Voyage.ac es el ejemplo de cómo se hace bien — por eso los trucos baratos ya no sirven.
