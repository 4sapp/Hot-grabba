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

---

Ambos métodos cometen el mismo error: miran el estado presente y no el historial. Un "Running" no prueba que nunca se detuvo, y una lista de procesos limpia no prueba que no hay código inyectado.
