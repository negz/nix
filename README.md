# nix

The Nix configuration for my M1 Mac. 

![My NixOS Setup!](nix.png "A screenshot of my NixOS terminals")

The goal here is to:

* Have a _somewhat_ lightweight Linux VM in which to run the Docker daemon.
* Leverage said Linux VM for not-containers things from time to time.
* Manage both the MacOS host and the Linux VM using the same, declarative tool.

I use [nix-darwin] to configure the Mac's command-line environment. I also run a
headless [NixOS] VM in Parallels. My user on both is configured using
[home-manager].

[nix-darwin]: https://github.com/LnL7/nix-darwin
[NixOS]: https://nixos.org
[home-manager]: https://github.com/nix-community/home-manager
