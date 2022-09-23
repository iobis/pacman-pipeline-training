# pacman-pipeline-training

Training materials for the PacMAN bioinformatics pipeline.

## Server configuration
### Setup conda for all users

```
cd /opt
sudo wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh
sudo chmod +x Miniconda3-py39_4.12.0-Linux-x86_64.sh
sudo ./Miniconda3-py39_4.12.0-Linux-x86_64.sh
sudo groupadd condausers
sudo chgrp -R condausers /opt/miniconda3/
sudo chmod 775 -R /opt/miniconda3/
sudo chown -R :condausers /mnt/lfw-ds001-v019/data
sudo chmod -R 775 /mnt/lfw-ds001-v019/data
```

### Create user account

```
sudo adduser testuser
sudo adduser testuser condausers
```

Add to `/home/testuser/.bashrc`:

```
export PATH="/opt/miniconda3:$PATH"
```

Conda init:

```
su - testuser
conda init
```

Add to `/home/testuser/.bashrc`:

```
cd PacMAN-pipeline
conda activate snakemake
```
