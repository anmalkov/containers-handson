#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app
EXPOSE 5000

FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY ["HelloWorld.Api/HelloWorld.Api.csproj", "HelloWorld.Api/"]
RUN dotnet restore "HelloWorld.Api/HelloWorld.Api.csproj"
COPY . .
WORKDIR "/src/HelloWorld.Api"
RUN dotnet build "HelloWorld.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "HelloWorld.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "HelloWorld.Api.dll"]