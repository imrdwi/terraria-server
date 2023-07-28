#!/bin/bash
#shellcheck disable=2164

# Installing/updating mods
mkdir -p $HOME/.local/share/Terraria
./manage-tModLoaderServer.sh -u --mods-only --check-dir $HOME/.local/share/Terraria --folder $HOME/.local/share/Terraria/wsmods

# Symlink terraria's local dotnet install so that it can persist through runs
mkdir -p $HOME/.local/share/Terraria/dotnet
ln -s $HOME/.local/share/Terraria/dotnet/ $HOME/tModLoader/dotnet

echo "Launching tModLoader..."
cd $HOME/tModLoader
# Maybe eventually steamcmd will allow for an actual steamserver. For now -nosteam is required.
exec ./start-tModLoaderServer.sh -config $HOME/.local/share/Terraria/serverconfig.txt -nosteam -steamworkshopfolder $HOME/.local/share/Terraria/wsmods/steamapps/workshop
