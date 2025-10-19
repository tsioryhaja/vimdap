# VIM Debug Adapter Protocol client

This project is a debug adapter protocol for VIM.   
It is supposed to be used with a low end and old computer.  
It was not really made to be ready to use, it was made to be easily configurable.  

## Configuration

For now, the only supported configuration is a specific configuration that actually contain both the debug adapter specification and the client's configuration.  

It is a Json file named ".dap-adapters.json" at the root of the project.   

Here is a example of a configuration file.  

```json
[
    {
        "name": "test",
        "language": "python",
        "adapter": {
            "type": "executable",
            "command": "python",
            "args": ["/home/user/.dap-adapters/debugpy/src/debugpy/adapter"]
        },
        "configuration": {
            "request": "launch",
            "program": "main.py",
            "justMyCode": false,
            "env": {
                "SOME_ENV": "Some Env value"
            }
        }
    }
]
```

It's a list that acontains all the dap configurations.   
Here is the explanation of the structure of the dict.  

* name: it's the display name of the debug configuration that will be used to choose which one to start.  
* language: This is just used for information, it allows other people to see what language is it for.
* adapter: this is the debug adapter's specification. It is used by the client to spawn the debug adapter. I'm working on a way to make it possible to have this preconfigured somewhere else so that you will not need to know how to manually launch the debug adapter.
* configuration: this is the debug adapter configuration. It is the configuration that is specific for the project. It's something that you can adapt from VSCode's .vscode/launch.json.

## WHy?

So this was made because of three reasons:   
* I have to debug project on WSL with an older computer that runs Windows 11.   
* I sometime uses a very old computer that struggle with neovim.   
* I just wanted to experiment and have some fun (main reason?)

## Who is it for?

This was made to work a bit like nvim-dap from Neovim but with some changes that I actually wanted.   
It is an experimental project so it's still NOT production ready.  

It is also something that does nto try to be an IDE like UI.   
It is also design to be very configurable. And it's not a ready to use solution. You will need to know how to configure the debug adapter you are going to use for it to work.   

So who is this for?   
### Not for Noevim users.

If you are on Neovim, use [nvim-dap](https://github.com/mfussenegger/nvim-dap).   
It is way more stable and a proven solution. This was designed with my nvim-dap user experience in mind.   
So I think you can get the same user experience with nvim-dap so I decided that it will not be Neovim compatible no mapper what.   

### Not a ready to use IDE like solution.

If you are on vim and just want to start debugging without having to learn how the debug adapter works, it's not for you.   
This was made so that you can easily extend it and also allow you to configure and specify you own debug adapter.  
It will need you to have a minimal understanding of the DAP protocol and how you debug adapter works.   
It will also not give you an IDE like UI. It's supposed to be minimalist.  
If you need al of that, I think you should use [vimspector](https://github.com/puremourning/vimspector).   
It is also a well proven solution (a coworker of mine uses it). It's just not really the kind of experience I want to have when I debug, but it's actually great.
