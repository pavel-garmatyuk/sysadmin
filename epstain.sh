#!/bin/bash #Как видите, здесь располагается шебанг, о котором мы уже упоминали.
# Author: Alexander Epstein https://github.com/alexanderepstein 

currentVersion="1.13.2"     #
configuredClient=""     # Здесь задаются переменные
configuredPython=""     #

## This function determines which http get tool the system has installed and returns an error if there isnt one
getConfiguredClient()               # Здесь задаётся функция. Функция - это фрагмент кода, 
                                    # к которому можно обратиться в любом месте программы. Их
                                    # мы будем проходить чуть позже.
{
  if  command -v curl &>/dev/null ; then             # Здесь, как видите, используется ветвление.
    configuredClient="curl"                          # Т.е. вся функция, про которую вы не знаете,
  elif command -v wget &>/dev/null ; then            # построена на достаточно простом принципе.
    configuredClient="wget"                          # Она получает некоторые данные, как команда
  elif command -v fetch &>/dev/null ; then           # и обрабатывает их, возвращая результат.
    configuredClient="fetch"                         # Также используются перенаправления вывода,
  else                                               # а про них вы уже тоже знаете.
    echo "Error: This tool reqires either curl, wget, or fetch to be installed."
    return 1
  fi

}

getConfiguredPython()   #Ещё одна функция. Она проверяет версию python.
{
  if  command -v python2 &>/dev/null ; then
    configuredPython="python2"
  elif command -v python &>/dev/null ; then
    configuredPython="python"
  else
    echo "Error: This tool requires python 2 to be installed."
    return 1
  fi
}


python()  #Функция с уже знакомым вам case и esac, а также служебными символами
{
  case "$configuredPython" in
    python2) python2 "$@";;
    python) python "$@";;
  esac
}

## Allows to call the users configured client without if statements everywhere
httpGet() #Ещё одна функция с case и esac.
{
  case "$configuredClient" in
    curl) curl -A curl -s "$@";;
    wget) wget -qO- "$@";;
    fetch) fetch -o "...";;
  esac
}

checkInternet() #Функция с перенаправлением вывода
{
  httpGet google.com > /dev/null 2>&1 || { echo "Error: no active internet connection" >&2; return 1; } # query google with a get request
}

## This function grabs information about a stock and using python parses the
## JSON response to extrapolate the information for storage
getStockInformation()              #А вот тут сложная функция. Задаются переменные, а внутри
{                                  #дополнительно обращаются к python. 
 stockInfo=$(httpGet  "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$1&apikey=KPCCCRJVMOGN9L6T") > /dev/null #grab the JSON response
  export PYTHONIOENCODING=utf8 #necessary for python in some cases
  echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['02. Exchange Name']" > /dev/null 2>&1 || { echo "Not a valid stock symbol" ; exit 1; } #checking if we get any information back from the server if not chances are it isnt a valid stock symbol 
                           #Задаём функцию stockinfo, которая забирает 
                           #информацию с сайта акций и проверяет, что вытащила корректную информацию
  # The rest of the code is just extrapolating the data with python from the JSON response
  exchangeName=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['02. Exchange Name']")
  latestPrice=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['03. Latest Price']")
  open=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['04. Open (Current Trading Day)']")
  high=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['05. High (Current Trading Day)']")
  low=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['06. Low (Current Trading Day)']")
  close=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['07. Close (Previous Trading Day)']")
  priceChange=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['08. Price Change']")
  priceChangePercentage=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['09. Price Change Percentage']")
  volume=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['10. Volume (Current Trading Day)']")
  lastUpdated=$(echo $stockInfo | python -c "import sys, json; print json.load(sys.stdin)['Realtime Global Securities Quote']['11. Last Updated']")
  unset stockInfo # done with the JSON response not needed anymore
} # Здесь просто распарсивание json ответа сайта.

## This function uses all the variables that are set by getStockInformation and
## prints them out to the user in a human readable format
printStockInformation()               # Функция, где при обращении к ней выводится уже
{                                     # информация по тому запросу, который вы делали.
  echo                                # При этом выводится она в псевдографике, которую вы
  echo $symbol stock info             # уже можете наблюдать в этом коде.
  echo "============================================="
  echo "| Exchange Name: $exchangeName"
  echo "| Latest Price: $latestPrice"
  if [[ $open != "--" ]];then echo "| Open (Current Trading Day): $open"; fi ## sometime this is blank only print if value is present             #А также снова работа с ветвлением и test 
  if [[ $high != "--" ]];then echo "| High (Current Trading Day): $high"; fi ## sometime this is blank only print if value is present
  if [[ $low != "--" ]];then echo "| Low (Current Trading Day): $low"; fi ## sometime this is blank only print if value is present
  echo "| Close (Previous Trading Day): $close"
  echo "| Price Change: $priceChange"
  if [[ $priceChangePercentage != "%" ]];then echo "| Price Change Percentage: $priceChangePercentage"; fi ## sometime this is blank only print if value is present
  if [[ $volume != "--" ]];then echo "| Volume (Current Trading Day): $volume"; fi ## sometime this is blank only print if value is present
  echo "| Last Updated: $lastUpdated"
  echo "============================================="
  echo
}

## This function queries google to determine the stock ticker for a certain company
## this allows the usage of stocks to be extended where now you can enter stocks appple
## and it will determine the stock symbol for apple is AAPL and move on from there
getTicker() # Функция с назначением переменных, перенаправлением вывода.
{
  input=$(echo "$@" | tr " " +)
  response=$(httpGet "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=$input&region=1&lang=en%22") > /dev/null
  symbol=$(echo $response | python -c "import sys, json; print json.load(sys.stdin)['ResultSet']['Result'][0]['symbol']") # using python to extrapolate the stock symbol
  unset response #just unsets the entire response after using it since all I need is the stock ticker
}

update() # Функция с ветвлением, назначением переменных.
{
  # Author: Alexander Epstein https://github.com/alexanderepstein
  # Update utility version 1.2.0
  # To test the tool enter in the defualt values that are in the examples for each variable
  repositoryName="Bash-Snippets" #Name of repostiory to be updated ex. Sandman-Lite
  githubUserName="alexanderepstein" #username that hosts the repostiory ex. alexanderepstein
  nameOfInstallFile="install.sh" # change this if the installer file has a different name be sure to include file extension if there is one
  latestVersion=$(httpGet https://api.github.com/repos/$githubUserName/$repositoryName/tags | grep -Eo '"name":.*?[^\\]",'| head -1 | grep -Eo "[0-9.]+" ) #always grabs the tag without the v option

  if [[ $currentVersion == "" || $repositoryName == "" || $githubUserName == "" || $nameOfInstallFile == "" ]];then
    echo "Error: update utility has not been configured correctly." >&2
    exit 1
  elif [[ $latestVersion == "" ]];then
    echo "Error: no active internet connection" >&2
    exit 1
  else
    if [[ "$latestVersion" != "$currentVersion" ]]; then
      echo "Version $latestVersion available"
      echo -n "Do you wish to update $repositoryName [Y/n]: "
      read -r answer
      if [[ "$answer" == "Y" || "$answer" == "y" ]] ;then
        cd  ~ || { echo 'Update Failed' ; exit 1 ; } # Снова переход в домашнюю директорию
        if [[ -d  ~/$repositoryName ]]; then rm -r -f $repositoryName  ||  { echo "Permissions Error: try running the update as sudo"; exit 1; } ; fi          # Ветвление
        git clone "https://github.com/$githubUserName/$repositoryName" || { echo "Couldn't download latest version" ; exit 1; }
        cd $repositoryName ||  { echo 'Update Failed' ; exit 1 ;} # Без комментариев.
        git checkout "v$latestVersion" 2> /dev/null || git checkout "$latestVersion" 2> /dev/null || echo "Couldn't git checkout to stable release, updating to latest commit."
        chmod a+x install.sh #this might be necessary in your case but wasnt in mine.
        ./$nameOfInstallFile "update" ||  exit 1     # Выше опять же знакомый вам chmod
        cd ..                                        # Здесь вы уже знаете, что это значит 
        rm -r -f $repositoryName ||  { echo "Permissions Error: update succesfull but cannot delete temp files located at ~/$repositoryName delete this directory with sudo"; exit 1; }
      else #Выше знакомая вам утилита удаления
        exit 1
      fi #Ветвление тут и далее
    else
      echo "$repositoryName is already the latest version"
    fi
  fi

}

usage() #Функция, которая при запросе выдаёт справку.
{
  echo "Stocks"
  echo "Description: Finds the latest information on a certain stock."
  echo "Usage: stocks [flag] or stocks [company/ticker]"
  echo "  -u Update Bash-Snippet Tools"
  echo "  -h Show the help"
  echo "  -v Get the tool version"
  echo "Examples:"
  echo "  stocks AAPL"
  echo "  stocks Tesla"
}

getConfiguredPython || exit 1    # Тут уже после объявления всех функций начинается
getConfiguredClient || exit 1    # их работа. Либо функция срабатывает и возвращает
                                 # какие-либо значения, либо выходит из программы
checkInternet || exit 1 # check if we have a valid internet connection if this isnt true the rest of the script will not work so stop here


while getopts "uvh" opt; do      # Цикл while, который проходили в этом модуле.
  case $opt in                   # case
    \?)
      echo "Invalid option: -$OPTARG" >&2 # Эхо c перенаправлением вывода
      exit 1
    ;;
    h)
      usage
      exit 0
    ;;
    v)
      echo "Version $currentVersion"
      exit 0
    ;;
    u)
      update
      exit 0
    ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
    ;;
  esac
done


if [[ $1 == "update" ]];then # Снова ветвление
  update
  exit 0
elif [[ $1 == "help" ]];then
  usage
  exit 0
elif [[ $# == "0" ]];then
  usage
  exit 0
else
  getTicker "$@" # the company name might have spaces so passing in all args allows for this  #И обращение к функциям, которые были описаны в начале кода.
  getStockInformation $symbol # based on the stock symbol exrapolated by the getTicker function get information on the stock
  printStockInformation  # print this information out to the user in a human readable format
  exit 0
fi #Конец программы, которая, как вы видите, заканчивается ветвлением.
