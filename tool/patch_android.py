#!/usr/bin/env python3
"""Prepara a pasta android/ gerada pelo `flutter create` na nuvem:

1. Copia o código nativo de native/ pra dentro (MainActivity com o canal,
   NotifService com a notificação de layout customizado, BootReceiver,
   SupabaseApi, layouts e ícones).
2. Injeta permissões, o serviço e o receiver no AndroidManifest.
3. Adiciona as dependências nativas (okhttp e androidx.core) no build.gradle.

Roda na nuvem (GitHub Actions) depois do flutter create. Idempotente.
"""
import os
import re
import shutil
import sys

MANIFEST = "android/app/src/main/AndroidManifest.xml"
KOTLIN_DST = "android/app/src/main/kotlin/com/rideblan/diario_do_bebe"
RES_DST = "android/app/src/main/res"

PERMISSIONS = """    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
"""

# Permite abrir o app de email pelo "Falar com a gente" (url_launcher/mailto).
QUERIES = """    <queries>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
    </queries>
"""

COMPONENTS = """        <service
            android:name=".NotifService"
            android:foregroundServiceType="specialUse"
            android:exported="false">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="Registro da rotina do bebe com botoes fixos na notificacao." />
        </service>
        <receiver android:name=".BootReceiver" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>
"""

DEPS_KTS = """
// Dependências do serviço da notificação (injetado pelo tool/patch_android.py).
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
}
"""

DEPS_GROOVY = """
// Dependências do serviço da notificação (injetado pelo tool/patch_android.py).
dependencies {
    implementation 'androidx.core:core-ktx:1.13.1'
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}
"""


def copy_native() -> None:
    os.makedirs(KOTLIN_DST, exist_ok=True)
    for f in os.listdir("native/kotlin"):
        shutil.copy(os.path.join("native/kotlin", f), os.path.join(KOTLIN_DST, f))
        print(f"copiado: {f} -> {KOTLIN_DST}")
    for root, _, files in os.walk("native/res"):
        rel = os.path.relpath(root, "native/res")
        dst = os.path.join(RES_DST, rel) if rel != "." else RES_DST
        os.makedirs(dst, exist_ok=True)
        for f in files:
            shutil.copy(os.path.join(root, f), os.path.join(dst, f))
            print(f"copiado: {rel}/{f} -> {dst}")


def patch_manifest() -> None:
    with open(MANIFEST, "r", encoding="utf-8") as f:
        xml = f.read()
    if "FOREGROUND_SERVICE_SPECIAL_USE" not in xml:
        xml = re.sub(r"(<application\b)", PERMISSIONS + r"\1", xml, count=1)
    if "android.intent.action.SENDTO" not in xml:
        xml = re.sub(r"(<application\b)", QUERIES + r"    \1", xml, count=1)
    if ".NotifService" not in xml:
        xml = xml.replace("</application>", COMPONENTS + "    </application>", 1)
    # Nome que aparece embaixo do ícone no celular (flutter create gera
    # "diario_do_bebe"; aqui vira o nome de verdade, com acento).
    xml = re.sub(
        r'android:label="[^"]*"',
        'android:label="Diário do Bebê"',
        xml,
        count=1,
    )
    with open(MANIFEST, "w", encoding="utf-8") as f:
        f.write(xml)
    print("AndroidManifest.xml: permissões + serviço + receiver + label ok.")


def patch_gradle() -> None:
    kts = "android/app/build.gradle.kts"
    groovy = "android/app/build.gradle"
    if os.path.exists(kts):
        path, deps = kts, DEPS_KTS
    elif os.path.exists(groovy):
        path, deps = groovy, DEPS_GROOVY
    else:
        print("ERRO: build.gradle do módulo app não encontrado.")
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    if "com.squareup.okhttp3" not in content:
        content += deps
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
    print(f"{path}: dependências nativas ok.")


def main() -> int:
    copy_native()
    patch_manifest()
    patch_gradle()
    return 0


if __name__ == "__main__":
    sys.exit(main())
