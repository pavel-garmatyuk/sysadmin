#!/usr/bin/bash

GREETINGS='"Greetings! \nHello ${USER}, it nice to meet you!"'
CHANGE_SHELL='\/usr\/bin\/bash'
USERS=$(sed 's/\s.*//' users.txt)

for user in ${USERS}
do
    #Cоздать пользователей из списка
    echo 'Create user ${user}'   
    #Добавить юзерам домашнюю директорию
    echo 'add home catalogiue'   
    useradd -m '${user}'
   
    #Записать привествие
    echo 'New greeting message'
    echo "echo -e ${GREETINGS}" >> /home/${user}/.bashrc
    #Меняем оболочку
    echo 'Changes shell to ${CHANGE_SHELL}'
    sed -i "/^${user}:/s/:.bin,sh$/:${CHANGE_SHELL}/" /etc/passwd
   

    #Меняем пароль
    echo 'change password'
    chpasswd < pass.txt