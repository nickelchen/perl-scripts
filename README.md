# perl-scripts

### FileTool

some funcs to manipulate files.

CAUTION: these funcs will modify file in place. backup files before use them.

usage:

```
use FileTool qw(read_file write_file
                replace replace_multiple
                find_replace find_replace_multiple
                prepend delete_lines
                flake8_visual_indent flake8_unused_lines );


```

read $file content to @lines array.
```
my @lines = read_file($file);

```

write @lines array to file
```
write_file($file, \@lines);

```

replace $oldstr with $newstr
```
replace($file, $oldstr, $newstr);

```

find files in $dir, filtered by $filters, then replace $oldstr with $newstr
```
find_replace($dir, $filters, $oldstr, $newstr);

```

like find_replace, but make multiple replacement at once. %replace_map is a hash
```
find_replace_multiple($dir, $filters, %replace_map)

eg:
find_replace_multiple('./', qr/\.py$/,
    (
        "old_string1" => "new_string1",
        "old_string2" => "new_string2"
    )
)

```

prepend $line to $file. $line doesn't has to end with `'\n'`, this func will add one.
```
prepend($file, $str)

```

delete lines with @linenos in $file
```
delete_lines($file, @linenos);

```

invoke flake8 uppon $dir and delete unused lines
```
flake8_unused_lines($dir);

```

invoke flake8 uppon $dir and reindent lines
```
flake8_visual_indent($dir);

```


