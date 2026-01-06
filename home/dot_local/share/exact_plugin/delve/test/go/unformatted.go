package main

import "fmt"

func hello(){
fmt.Println("bad indent")
if true{
fmt.Println("nested bad")
}
}
