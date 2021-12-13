# Mustach

simple mustache-like style templater in pure bash to multiple purposes. 
By this tool you can simple replace `{{VAR}}` by `$VAR` environment value.

# Examples

Example file `file.template` content:

```
VAR={{VAR}}
```

- Passing arguments directly

```
VAR=value mustash -f file.template
```

- Passing arguments by stdio

```
cat file.template | VAR=value mustash
```

- Passing arguments from env file 

By default script load environment variables from file called `.mustachenv` but you cant override file by `MUSTACH_ENV` variable

```
MUSTACH_ENV="prod.env" mustash -f file.template 
```
