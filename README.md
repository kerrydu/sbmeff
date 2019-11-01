# sbmeff
 Slacks-based Measure of Efficiency in Stata
 
## Installing within Stata

```
 net install sbmeff, from("https://raw.githubusercontent.com/kerrydu/sbmeff/master/")
```

 Alternatively, download the zipfile and unzip it to your computer disk. 
```
   copy https://codeload.github.com/kerrydu/sbmeff/zip/master sbmeff-master.zip
   unzipfile sbmeff-master.zip
   net install sbmeff, from(`c(pwd)'/sbmeff-master)
```
