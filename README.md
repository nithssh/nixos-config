# nixos-config 

## File permissions

The directory's group ownership has been set to `wheel` using

```sh
sudo chown -R :wheel .
sudo chmod g+s .
sudo chmod -R g+rw . # Update the RW perms of existing files
```
