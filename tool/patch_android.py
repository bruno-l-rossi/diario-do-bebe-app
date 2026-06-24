#!/usr/bin/env python3
"""Injeta no AndroidManifest gerado pelo `flutter create` o que o app precisa:
- INTERNET (Flutter nao adiciona no release por padrao; sem isso o app nao grava)
- permissoes do servico em primeiro plano (notificacao fixa)
- a declaracao do servico do flutter_foreground_task, tipo specialUse
  (sem timeout de 6h do dataSync; ok pra uso pessoal sem Play Store)

Roda na nuvem (GitHub Actions) depois do flutter create. Idempotente.
"""
import re
import sys

MANIFEST = "android/app/src/main/AndroidManifest.xml"

PERMISSIONS = """    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
"""

SERVICE = """        <service
            android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
            android:foregroundServiceType="specialUse"
            android:exported="false">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Registro da rotina do bebe com botoes fixos na notificacao." />
        </service>
"""


def main() -> int:
    with open(MANIFEST, "r", encoding="utf-8") as f:
        xml = f.read()

    if "FOREGROUND_SERVICE_SPECIAL_USE" not in xml:
        xml = re.sub(r"(<application\b)", PERMISSIONS + r"\1", xml, count=1)

    if "flutter_foreground_task.service.ForegroundService" not in xml:
        xml = xml.replace("</application>", SERVICE + "    </application>", 1)

    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(xml)

    print("AndroidManifest.xml patched.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
