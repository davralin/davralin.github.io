---
title: Flatpak-branch in ansible
description: Get defined flatpak-branch using flatpak-module in ansible
categories:
  - ansible
  - flatpak
tags:
  - ansible
  - flatpak
---

# Get defined flatpak-branch using flatpak-module in ansible

If you try to install the base-package `org.freedesktop.Platform.ffmpeg-full`, and you only get

````"cmd": "/usr/bin/flatpak install --system --noninteractive flathub org.freedesktop.Platform.ffmpeg-full", "item": "org.freedesktop.Platform.ffmpeg-full", "msg": "error: No ref chosen to resolve matches for ‘org.freedesktop.Platform.ffmpeg-full’", "rc": 1, "stderr": "error: No ref chosen to resolve matches for ‘org.freedesktop.Platform.ffmpeg-full’\n", "stderr_lines": ["error: No ref chosen to resolve matches for ‘org.freedesktop.Platform.ffmpeg-full’"], "stdout": "Similar refs found for ‘org.freedesktop.Platform.ffmpeg-full’ in remote ‘flathub’ (system):\n\n   1) runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/19.08\n   2) runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/20.08\n   3) runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/21.08\n\nWhich do you want to use (0 to abort)? [0-3]: 0\n", "stdout_lines": ["Similar refs found for ‘org.freedesktop.Platform.ffmpeg-full’ in remote ‘flathub’ (system):", "", "   1) runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/19.08", "   2) runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/20.08", "   3) runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/21.08", "", "Which do you want to use (0 to abort)? [0-3]: 0"]}````

If you run the flatpak-installer manually, you will recognize a prompt for choosing which branch of the package you want to select - you can simply copy the full name, and use that as the package name instead of the "short" name.

Like so:
````patch
diff --git a/roles/firefox/tasks/main.yml b/roles/firefox/tasks/main.yml
index 8edcf8ae..715d0ab6 100644
--- a/roles/firefox/tasks/main.yml
+++ b/roles/firefox/tasks/main.yml
@@ -7,4 +7,4 @@
   become: yes
   loop:
    - org.mozilla.firefox
-   - org.freedesktop.Platform.ffmpeg-full
+   - org.freedesktop.Platform.ffmpeg-full/x86_64/21.08
````