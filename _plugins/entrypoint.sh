#!/usr/bin/env bash
# Structure: Cell Types – Modulo 6
# https://www.hexspin.com/proof-of-confinement/

set_target() {
  
  # Get Structure
  if [[ "$2" == *"github.io"* ]]; then
    [[ -n "$ID" ]] && SPIN=$( echo $ID | sed 's/.* //')
    IFS=', '; array=($(pinned_repos.rb ${OWNER} | yq eval -P | sed "s/ /, /g"))
  else
    HEADER="Accept: application/vnd.github+json"
    echo ${INPUT_TOKEN} | gh auth login --with-token
	gh api -H "${HEADER}" /users/eq19/gists --jq '.[].url' > /tmp/gist_url
    gh api -H "${HEADER}" /users/eq19/gists --jq '.[].files.[].raw_url' > /tmp/gist_files
    IFS=', '; array=($(gh api -H "${HEADER}" /user/orgs  --jq '.[].login' | sort -uf | yq eval -P | sed "s/ /, /g"))
  fi
  
  # Iterate the Structure
  printf -v array_str -- ',,%q' "${array[@]}"
  if [[ ! "${array_str},," =~ ",,$1,," ]]; then SPAN=0; echo ${array[0]}
  elif [[ "${array[-1]}" == "$1" ]]; then SPAN=${#array[@]}; echo $2
  else
    for ((i=0; i < ${#array[@]}; i++)); do
      if [[ "${array[$i]}" == "$1" && "$i" -lt "${#array[@]}-1" ]]; then SPAN=$(( $i + 1 )); echo ${array[$SPAN]}; fi
    done
  fi
  
  # Generate id from the Structure
  [[ -z "$SPIN" ]] && if [[ "$1" != "$2" ]]; then SPIN=0; else SPIN=7; fi || SPIN=$(( 6*SPIN+SPIN ))
  [[ -z "$2" ]] && echo $(( $SPAN )) || return $(( $SPAN + $SPIN ))
}

jekyll_build() {

  git config --global user.name "${GITHUB_ACTOR}" && git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
  git config --global --add safe.directory ${GITHUB_WORKSPACE} && rm -rf .github && mv /maps/.github . && git add .
  git commit -m "update workflow" > /dev/null && git push > /dev/null 2>&1

  echo -e "\n$hr\nWORKSPACE\n$hr"
  cd /maps && mv _includes/workdir/* .
  if [[ $1 == *"github.io"* ]]; then mv _assets assets; fi
  wget -O README.md $(cat /tmp/gist_files | awk "NR==$2") &>/dev/null && ls -al .

  echo -e "\n$hr\nCONFIG\n$hr"
  sed -i "1s|^|target_repository: $1\n|" _config.yml
  sed -i "1s|^|repository: $GITHUB_REPOSITORY\n|" _config.yml
  sed -i "1s|^|ID: $(( $2 + 30 ))\n|" _config.yml && cat _config.yml

  echo -e "\n$hr\nBUILD\n$hr"
  # https://gist.github.com/DrOctogon/bfb6e392aa5654c63d12
  REMOTE_REPO="https://${GITHUB_ACTOR}:${INPUT_TOKEN}@github.com/$1.git"
  JEKYLL_GITHUB_TOKEN=${INPUT_TOKEN} bundle exec jekyll build --profile -t -p /maps/_plugins/gem
  
  cd _site && git init --initial-branch=master > /dev/null && git remote add origin ${REMOTE_REPO}
  if [[ $1 == "eq19/eq19.github.io" ]]; then echo "www.eq19.com" > CNAME; fi && touch .nojekyll && git add .
  git commit -m "jekyll build" > /dev/null && git push --force ${REMOTE_REPO} master:gh-pages

  echo -e "\n$hr\nDEPLOY\n$hr"
  ls -al
}

# https://unix.stackexchange.com/a/615292/158462
[[ ${GITHUB_REPOSITORY} == *"github.io"* ]] && OWNER=$(set_target ${OWNER} ${GITHUB_ACTOR}) || ID=$(set_target ${OWNER} ${ID})
TARGET_REPOSITORY=$(set_target $(basename ${GITHUB_REPOSITORY}) ${OWNER}.github.io)
jekyll_build ${OWNER}/${TARGET_REPOSITORY} $?