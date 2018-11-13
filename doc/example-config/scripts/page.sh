# page.sh --- generate a new page.

read -p "Page slug name: " slug
read -p "Page title: " title
read -p "Two-letter language code: " language
filename="$SRCDIR/$slug.textile"

if [ -f $filename ]; then
    echo A page with name $filename already exists.
    exit 1
fi

cat <<EOF > $filename
Title: $title
Template: page
Language: $language

EOF

echo New page created at: $filename


exec $EDITOR $filename
