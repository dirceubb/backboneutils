###################################################################################
### Build and Run Docker Images for .NET app                                  ###
### I used this guide https://docs.microsoft.com/en-us/dotnet/core/docker/build-container?tabs=windows ###
###################################################################################

## Add the Microsoft package signing key to your list of trusted keys and add the package repository ##
wget https://packages.microsoft.com/config/ubuntu/21.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

## Install the .NET SDK ##
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-6.0

## Crear un nuevo proyecto ##
mkdir dotnet-app
cd dotnet-app
dotnet new console -o App -n DotNet.Docker
## Probar app ##
cd app
dotnet run

## Modify program.cs ##
vim Program.cs

var counter = 0;
var max = args.Length != 0 ? Convert.ToInt32(args[0]) : -1;
while (max == -1 || counter < max)
{
    Console.WriteLine($"Counter: {++counter}");
    await Task.Delay(1000);
}

## Save the file and test the program again ##
dotnet run
dotnet run -- 10

## It is best to have the container run the published version of the app. To publish the app, run the following command ##
dotnet publish -c Release

## listing of the publish folder to verify that the DotNet.Docker.dll file was created ##
ls bin/Release/net6.0/publish/

## Create the Dockerfile ##
vim Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:6.0
COPY bin/Release/net6.0/publish/ App/
WORKDIR /App
ENTRYPOINT ["dotnet", "DotNet.Docker.dll"]


## Build docker image ##
docker build -t dotnet-app -f Dockerfile .

## Create a container ##
docker create --name dotnet-app-container dotnet-app

## Manage de Container ##
## Start Container ##
docker start dotnet-app-container
docker ps

## Connect to a container ##
docker attach --sig-proxy=false dotnet-app-container