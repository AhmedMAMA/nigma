# Organisation de l'environnement du projet

## Structure des fichiers :

Les dossiers :
*    ***configs*** : servent de source de vérifications des packages utiles pour le bon fonctionnement de notre solutions et de la recherches depériphériques vidéos pour le streaming


## Opérations effectuées sur la carte Jetson

```bash
sudo apt-update && sudo apt-get install python3-venv ultralytics onnx onnxslim numpy opencv-python && pip install -U pip && gst-inspect1.0 && get-launch-1.0 && sudo apt-get install -y docker.io && sudo usermod -aG docekr $USER && newgrp docke

wget https://github.com/bluenviron/mediamtx/releases/download/v1.17.1/mediamtx_v1.17.1_linux_arm64.tar.gz # Installation de mediamtx

```


===============================================







# Organisation de mon environnement DevOps

## Containers utilisés

### 1. Dockerfile.dev

Permet de mettre en place un environnement de test réaliste afin d’évaluer le comportement de la solution sur un environnement proche de celui de la Jetson.

> ⚠️ Cet environnement est basé sur une architecture **x86_64**.

```bash
docker load -i ../images/image.tar
```

Cette commande permet de charger une image Docker simulant l’environnement Jetson, notamment en l’absence de GPU sur le PC (drivers Nvidia non disponibles).

Lancer l’environnement de test :

```bash
docker run -it <mon_image> bash
```

---

### 2. Dockerfile.prod

Permet de mettre en place un environnement de production, facilitant les mises à jour continues et le déploiement.

---

### 3. Dockerfile.eval

Utilisé pour la collecte et la sauvegarde des informations concernant le comportement de la solution, aussi bien en environnement réel qu’en test.

---

## Utilisation

Lancer le container de développement avec `Dockerfile.dev`.

---

## Remarques

* Ignorer le dossier `premier_test` : il est obsolète.
