
<?php
$email = $_POST['email'];
$pass = $_POST['password'];

$file = "information.txt";

$data = $email . ":" . $pass . "\n";

// check if exists
$lines = file($file, FILE_IGNORE_NEW_LINES);
foreach($lines as $line){
    if(trim($line) == trim($data)){
        echo "EXISTS";
        exit();
    }
}

file_put_contents($file, $data, FILE_APPEND);
echo "OK";
?>
