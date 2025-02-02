#!/usr/bin/env bash
# Structure: Cell Types – Modulo 6
# https://www.hexspin.com/proof-of-confinement/

set_target() {
  
  # Get Structure
  if [[ $2 == *"github.io"* ]]; then
    [[ -n "$CELL" ]] && SPIN=$(( $CELL * 13 ))
    pinned_repos.rb ${OWNER} public | yq eval -P | sed "s/ /, /g" > /tmp/pinned_repo
    [[ "${OWNER}" != "eq19" ]] && sed -i "1s|^|maps, feed, lexer, parser, syntax, grammar, |" /tmp/pinned_repo
    IFS=', '; array=($(cat /tmp/pinned_repo))
  else
    gh api -H "${HEADER}" /user/orgs  --jq '.[].login' | sort -uf | yq eval -P | sed "s/ /, /g" > /tmp/user_orgs
    IFS=', '; array=($(cat /tmp/user_orgs))
    echo "[" > /tmp/orgs.json
    for ((i=0; i < ${#array[@]}; i++)); do
      IFS=', '; pr=($(pinned_repos.rb ${array[$i]} public | yq eval -P | sed "s/ /, /g"))      
      gh api -H "${HEADER}" /orgs/${array[$i]} | jq '. +
        {"key1": ["maps","feed","lexer","parser","syntax","grammar"]} +
        {"key2": ["'${pr[0]}'","'${pr[1]}'","'${pr[2]}'","'${pr[3]}'","'${pr[4]}'","'${pr[5]}'"]}' >> /tmp/orgs.json
      if [[ "$i" -lt "${#array[@]}-1" ]]; then echo "," >> /tmp/orgs.json; fi
    done
    echo "]" >> /tmp/orgs.json
  fi
  
  # Iterate the Structure
  printf -v array_str -- ',,%q' "${array[@]}"
  if [[ ! "${array_str},," =~ ",,$1,," ]]; then
    SPAN=0; echo ${array[0]}
  elif [[ "${array[-1]}" == "$1" ]]; then
    SPAN=${#array[@]}; echo $2 | sed "s|${OWNER}.github.io|${ENTRY}.github.io|g"
    if [[ -n "$CELL" ]]; then    
      pinned_repos.rb ${ENTRY} public | yq eval -P | sed "s/ /, /g" > /tmp/pinned_repo
      [[ "${ENTRY}" != "eq19" ]] && sed -i "1s|^|maps, feed, lexer, parser, syntax, grammar, |" /tmp/pinned_repo
    fi
  else
    for ((i=0; i < ${#array[@]}; i++)); do
      if [[ "${array[$i]}" == "$1" && "$i" -lt "${#array[@]}-1" ]]; then 
        SPAN=$(( $i + 1 )); echo ${array[$SPAN]}
      fi
    done
  fi
  
  # Generate id from the Structure
  [[ -z "$SPIN" ]] && if [[ "$1" != "$2" ]]; then SPIN=0; else SPIN=13; fi
  if [[ -n "$CELL" ]]; then
    SPANPLUS=$(($SPAN + 1))
    if (( $CELL == 0 )); then MOD=7; else MOD=13; fi
    if (( $SPANPLUS == $MOD )); then 
      SPANPLUS=0
      CELLPLUS=$(($CELL + 1))
      if (( $CELLPLUS == 14 )); then CELLPLUS=0; fi
    else
      CELLPLUS=$(($CELL + 0))
    fi
    
    echo "  spin: [${CELLPLUS}, ${SPANPLUS}]" >> /maps/_config.yml
    echo "  pinned: [$(cat /tmp/pinned_repo)]" >> /maps/_config.yml
    echo "  organization: [$(cat /tmp/user_orgs)]" >> /maps/_config.yml
  fi
  return $(( $SPAN + $SPIN ))
}

jekyll_build() {

  echo -e "\n$hr\nCONFIG\n$hr"
  [[ $1 == *"github.io"* ]] && OWNER=$2
  if [[ $1 != "eq19.github.io" ]]; then SITEID=$(( $3 + 2 )); else SITEID=1; fi

  if  [[ "${OWNER}" == "eq19" ]]; then
    sed -i "1s|^|description: An attempt to discover the Final Theory\n\n|" /maps/_config.yml
  else
    DESCRIPTION=$(gh api -H "${HEADER}" /orgs/${OWNER} --jq '.description')
    sed -i "1s|^|description: ${DESCRIPTION}\n\n|" /maps/_config.yml
  fi
  
  # Note: If you need to use a workflow run's URL from within a job, you can combine
  # these variables: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID
  sed -i "1s|^|action: ${REPO}/actions/runs/${RUN}\n|" /maps/_config.yml
  sed -i "1s|^|repository: ${OWNER}/$1\n|" /maps/_config.yml
  [[ $1 != *"github.io"* ]] && sed -i "1s|^|baseurl: /$1\n|" /maps/_config.yml
  
  sed -i "1s|^|title: eQuantum\n|" /maps/_config.yml
  FOLDER="span$(( 17 - $3 ))" && sed -i "1s|^|span: ${FOLDER}\n|" /maps/_config.yml
  sed -i "1s|^|user: ${USER}\n|" /maps/_config.yml
  sed -i "1s|^|id: ${SITEID}\n|" /maps/_config.yml
  cat /maps/_config.yml
 
  echo -e "\n$hr\nSPIN\n$hr"
   gist.sh $1 ${OWNER} ${FOLDER} #&>/dev/null
  find /tmp/gistdir -type d -name .git -prune -exec rm -rf {} \;
  
  cd /tmp/workdir 
  rm -rf /tmp/Sidebar.md && cp _Sidebar.md /tmp/Sidebar.md
  sed -i 's/0. \[\[//g' /tmp/Sidebar.md && sed -i 's/\]\]//g' /tmp/Sidebar.md

  find . -iname '*.md' -print0 | sort -zn | xargs -0 -I '{}' front.sh '{}'
  find . -type d -name "${FOLDER}" -prune -exec sh -c 'cat /tmp/README.md >> $1/README.md' sh {} \;
  
  echo -e "\n$hr\nWORKSPACE\n$hr"
  #NR=$(cat /tmp/gist_files | awk "NR==$(( $3 + 2 ))")
  #[[ ! -f README.md ]] && wget -O README.md ${NR} &>/dev/null
  #rm -rf README.md && cp /tmp/workdir/exponentiation/span16/README.md .
  mkdir /tmp/workdir/_data && mv -f /tmp/orgs.json /tmp/workdir/_data/orgs.json
  cp -R /tmp/gistdir/* . && cp -R /maps/_* . && mv _assets assets && ls -al

  echo -e "\n$hr\nBUILD\n$hr"
  # Jekyll Quick Reference https://gist.github.com/DrOctogon/bfb6e392aa5654c63d12
  JEKYLL_GITHUB_TOKEN=${INPUT_TOKEN} bundle exec jekyll build --profile -t -p /maps/_plugins/gems
  
  echo -e "\n$hr\nDEPLOY\n$hr"
  cd ${GITHUB_WORKSPACE}/.devcontainer && mv -f /tmp/workdir/_site .
  cd _site && touch .nojekyll && mv /tmp/workdir/README.md .
  if [[ $1 == "eq19.github.io" ]]; then echo "www.eq19.com" > CNAME; fi && ls -al . && echo -e "\n"
  
CREDENTIAL=${INPUT_TOKEN}
[[ "${OWNER}" != "${USER}" ]] && CREDENTIAL=${INPUT_OWNER}
REMOTE_REPO="https://${ACTOR}:${CREDENTIAL}@github.com/${OWNER}/$1.git"
git init --initial-branch=master > /dev/null && git remote add origin ${REMOTE_REPO}
#git add . && git commit -m "jekyll build" > /dev/null && git push --force ${REMOTE_REPO} master:gh-pages

}

# Set update workflow
git config --global user.name "${ACTOR}"
git config --global --add safe.directory ${GITHUB_WORKSPACE}
git config --global user.email "${ACTOR}@users.noreply.github.com"

rm -rf .github && mv /maps/.github . && chown -R "$(whoami)" .github
#[[ "${OWNER}" == "${USER}" ]] && sed -i 's/feed/lexer/g' .github/workflows/main.yml
git add . && git commit -m "Assign eQuantum to project workflow" > /dev/null && git push > /dev/null 2>&1

# Get structure on gist files
HEADER="Accept: application/vnd.github+json"
echo ${INPUT_TOKEN} | gh auth login --with-token
PATTERN='sort_by(.created_at)|.[] | select(.public == true).files.[] | select(.filename != "README.md").raw_url'
gh api -H "${HEADER}" /users/eq19/gists --jq "${PATTERN}" > /tmp/gist_files

# Remove Existing Self-Hosted Runner
# See: https://docs.github.com/en/rest/actions/self-hosted-runners
TOTAL_COUNT=$(gh api -H "${HEADER}" /repos/${REPO}/actions/runners --jq '.total_count')
if (( $TOTAL_COUNT == 1 )); then
  RUNNER_ID=$(gh api -H "${HEADER}" /repos/${REPO}/actions/runners --jq '.runners.[].id')
  gh api --method DELETE -H "${HEADER}" /repos/${REPO}/actions/runners/${RUNNER_ID}
fi 

# Capture the string and return status
if [[ "${OWNER}" != "${USER}" ]]; then ENTRY=$(set_target ${OWNER} ${USER}); else ENTRY=$(set_target ${OWNER}); fi
CELL=$? && TARGET_REPOSITORY=$(set_target $(basename ${REPO}) ${OWNER}.github.io)
jekyll_build ${TARGET_REPOSITORY} ${ENTRY} $?
