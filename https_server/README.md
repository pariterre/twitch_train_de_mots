# What is this
This is a simple HTTPS server that serves can be used to test the `configuration` and `frontends` of the Twitch program.

# How to use
1. Make sure the required dependencies are installed using `conda env create -f environment.yml`
2. Load the environment using `conda activate train_de_mots`
3. Make sure the required frontend (`configuration` and/or `frontends`) are built
4. Run the server using `python https_server.py`

# What will happen
1. A symlink to `../configuration/build/web/` to `./configuration/` and a symlink to `../frontends/video_component/build/web/` to `./video_component/` will be created. 
2. A new self-signed certificate will be generated and saved in the `certs` directory.
3. The server will then serve the content of the `video_component` and `configuration` directories on `https://localhost:8080/configuration` and `https://localhost:8080/video_component/` respectively.
