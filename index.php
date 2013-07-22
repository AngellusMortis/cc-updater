<?php
    error_reporting(E_ERROR);
    header("Content-Type: text/plain");
    header("Cache-Control: no-cache, must-revalidate");
    header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");
    function getFiles($path) {
        $base = getcwd() . "/$path";
        $files = array();
        foreach (scandir($base) as $file) {
            if ($file != "." && $file != "..") {
                $ext = pathinfo($file, PATHINFO_EXTENSION); 
                if (is_dir($base . "/" . $file)) {
                    $files = array_merge($files, getFiles($path . $file . "/"));
                }
                else if ($ext == "lua") { 
                    $handle = fopen($base . "/" . $file, "r");
                    fgets($handle);
                    $versionLine = fgets($handle);
                    $index = strpos($versionLine, "\"");
                    $splited = explode(".", $file);
                    $splited = $splited[0];
                    array_push($files, array($path, $splited, substr($versionLine, $index+1, strpos($versionLine, "\"", $index+1)-$index-1)));
                    fclose($handle);
                }
            }
        }
        return $files;
    }

    $path = getcwd() . "/am/";
    $files = getFiles("");
    foreach ($files as $file) {
        echo $file[0] . "\n" . $file[1] . "\n" . $file[2] . "\n"; 
    }