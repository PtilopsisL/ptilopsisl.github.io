git checkout master
git branch -D blog
git branch blog
git checkout blog
mkdocs build

while read file; do
	rm -rf $file
done <<< `find . ! -wholename "." ! -wholename "./.git*" ! -wholename "./site*" ! -wholename "./assets*"`

cp -r ./site/* ./
rm -rf site

git add .
git commit -m "build site"
git push -u origin master
git push -u origin -f blog
