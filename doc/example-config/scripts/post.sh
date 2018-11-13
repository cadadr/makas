# post.sh --- generate a new post.

blogdir=$SRCDIR/path/to/blog
date=$(date +"%Y%m%d")
read -p "Post slug name: " slug
read -p "Post title: " title
read -p "Two-letter language code: " language
read -p "Short description: " description

id="$date"
num=2
while test "$(find $blogdir -name $id\*)"; do
    id="${date}_$num"
    num=$(($num+1))
done

filename="$blogdir/${id}_$slug.textile"

if [ -f $filename ]; then
    echo A post with name $filename already exists.
    echo There is something wrong, this is an unlikely coincidence.
    echo Maybe try a slug you did not use already today?
    exit 1
fi

cat <<EOF > $filename
Title: $title
Template: page
Language: $language
Description: $description

EOF

echo New post created at: $filename


exec $EDITOR $filename

