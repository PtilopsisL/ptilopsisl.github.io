git checkout master
git branch -d blog
git branch blog
git checkout blog
mkdocs build

while read file; do
	rm -rf $file
done <<< `find . ! -wholename "." ! -wholename "./.git*" ! -wholename "./site*"`

git add .
git commit -m "build site"
git push -u origin master
git push -u origin -f blog
