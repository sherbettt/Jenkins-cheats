#!/bin/bash

#основной https://github.com/sherbettt/Jenkins-cheats
#запасные https://gitflic.ru/project/kkorablin/jenkins-cheats и https://gitverse.ru/sherbettt/Jenkins-cheats

# Определяем цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'


#echo -e "${GREEN}=== Git Pull ===${NC}"
printf "${GREEN}=== Git Pull ===${NC}\n"
git pull;

printf "${GREEN}=== Git Push gitflic.ru ===${NC}\n"
git push git@gitflic.ru:kkorablin/jenkins-cheats.git;

printf "${GREEN}=== Git Push gitverse.ru ===${NC}\n"
git push git@gitverse.ru:sherbettt/Jenkins-cheats.git
