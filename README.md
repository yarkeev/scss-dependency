Get list dependency of scss/sass file

## Example:
```
scssDependency = require('scss-dependency');

//get hash of last commit
scssDependency('sass/main.scss', function (deps) {
	console.log(deps);
});
```