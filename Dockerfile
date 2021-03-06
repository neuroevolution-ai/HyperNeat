FROM jupyter/base-notebook:latest

# Switch to root user to install packages
USER root

# Map to your user id on the host to be able to mount a volume where the user inside docker has write access
RUN usermod -u 1000 $NB_USER

# Update the system and install base and roboschool requirements
RUN apt-get update -y && apt-get install -y git xvfb ffmpeg libgl1-mesa-dev libharfbuzz0b libpcre3-dev libqt5x11extras5

# Switch back to unprivileged user for python packages. User is defined in base docker image
USER $NB_USER

# NumPy has changed something in version 1.17+ which causes import errors in TensorFlow. Until this fix is merged
# use a slightly older version of NumPy, same with gast
RUN conda install --quiet --yes \
    'gast==0.2.2' \
    'matplotlib' \
    'pandas' \
    'ipywidgets'

RUN conda clean --yes --all -f && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Roboschool is deprecated after version 1.0.48
# Install TensorFlow and NumPy with pip to prevent using the MKL version which in this implementation is slower
RUN pip install --quiet \
    numpy==1.17.2 \
    tensorflow==2.0.0 \
    keras==2.3.1 \
    gym[atari] \
    roboschool==1.0.48 \
    opencv-python \
    neat-python

# $NB_USER == jovyan and his group is users, docker does not support dynamic substitution in chown
# ADD --chown=jovyan:users . work/evolution-strategies/

WORKDIR work/evolution-strategies/

# Run jupyter notebook with a fake display to allow rendering in roboschool as suggested here:
# https://github.com/openai/gym#rendering-on-a-server
CMD ["xvfb-run", "-s", "-screen 0 1400x900x24", "start-notebook.sh", "--NotebookApp.password='sha1:9eeee5ad359d:b3a4cf67b0e0cbdf8ad4a63d8c2df3702bc26b33'"]
