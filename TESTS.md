Tous les tests sont à faire sur 

- ubuntu 18.04
- ubuntu 20.04
- Debian 9
- Debian 10


Prérequis : 
- un user "normal" (non root), qui puisse faire du sudo. 
- si possible une vm neuve



Cloner le dépot :

```
sudo git clone https://github.com/projetssd/ssdv2.git /opt/seedbox-compose
sudo chown -R ${USER}: /opt/seedbox-compose  # changer user par votre username
```

puis avec le user
```
cd /opt/seedbox-compose
sudo ./prerequis.sh
./seedbox.sh
```

et se laisser guider

## Tests à faire :

lancer seedbox.sh, puis installer la gui (choix 999 caché) et vérifier que tout est ok.
