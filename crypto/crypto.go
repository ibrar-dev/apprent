package main

import (
	"crypto/rsa"
	"crypto/rand"
	"fmt"
	"math/big"
	"net"
	"path/filepath"
	"net/http"
	"os"
	"encoding/json"
	"bytes"
	"encoding/base64"
	"encoding/hex"
	"crypto/sha256"
	"crypto/aes"
	"crypto/cipher"
	"log"
	"io/ioutil"
)

var (
	pmh string
	sf  string
	ppk *rsa.PrivateKey
)

type cipherMsg struct {
	Cipher string   `json:"cipher"`
	Key    *big.Int `json:"key"`
}

type cryptoHandler struct {}

func (c *cryptoHandler) init(pKey *big.Int) {
	keyString := []byte(pKey.String())
	hashed := sha256.Sum256(keyString)
	hash :=  hex.EncodeToString(hashed[:])

	key := []byte(hash[0:32])
	iv := []byte(hash[32:48])

	block, _ := aes.NewCipher(key)

	mode := cipher.NewCBCDecrypter(block, iv)

	d, _ := hex.DecodeString(pmh)

	final := make([]byte, 4096)

	mode.CryptBlocks(final, d)

	last := new(big.Int)
	last.SetString(string(final), 10)

	ppk = &rsa.PrivateKey{PublicKey: rsa.PublicKey{N: pKey, E: 65537}, D: last}
}

func (c *cryptoHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()

	body := make([]byte, 4096)
	r.Body.Read(body)
	request := cipherMsg{}

	json.Unmarshal(bytes.Trim(body, "\x00"), &request)

	if request.Cipher != "" {
		cipherText, _ := base64.StdEncoding.DecodeString(request.Cipher)

		decrypted, _ := rsa.DecryptPKCS1v15(rand.Reader, ppk, cipherText)

		w.Write(decrypted)
	} else {
		c.init(request.Key)
	}
}

func server(cHandler cryptoHandler) {
	if sf == "" {
		sf = "./server.sock"
	}
	absPath, _ := filepath.Abs(sf)
	log.Println(absPath)
	os.Remove(absPath)
	unixListener, err := net.Listen("unix", absPath)
	if err != nil {
		log.Println(err)
		panic(err)
	}
	server := http.Server{Handler: &cHandler}
	fmt.Print("Starting Server")
	server.Serve(unixListener)
}

func main() {
	arg := os.Args
	if len(arg) >= 2 && arg[1] == "gen" {
		generateKeys()
	} else {
		f := setLogs()
		defer f.Close()
		if pmh == "" {
			panic("missing hash")
		}
		cHandler := cryptoHandler{}
		server(cHandler)
	}
}

func setLogs() (*os.File){
	f, err := os.OpenFile("log.log", os.O_RDWR | os.O_CREATE | os.O_APPEND, 0666)
	if err != nil {
		panic("error opening log file")
	}

	log.SetOutput(f)
	log.Println("Starting...")
	return f
}

func generateKeys() {
	// Generate a key of length 2048
	key, _ := rsa.GenerateKey(rand.Reader, 2048)
	// Get modulus of public key
	public := key.PublicKey.N
	// Get exponent of private key
	D := key.D
	// Write string representation to file
	ioutil.WriteFile("pub.key", []byte(public.String()), 0644)

	// 
	keyString := []byte(public.String())
	hashed := sha256.Sum256(keyString)
	hash :=  hex.EncodeToString(hashed[:])

	// First 32 chars of hash
	cipherKey := []byte(hash[0:32])
	// Next 16 chars of hash
	iv := []byte(hash[32:48])

	block, _ := aes.NewCipher(cipherKey)

	mode := cipher.NewCBCEncrypter(block, iv)

	final := make([]byte, 4096)

	padded := pad([]byte(D.String()))
	mode.CryptBlocks(final, padded)
	hexed := []byte(hex.EncodeToString(final))
	trimmed := bytes.Trim(hexed, "0")
	ioutil.WriteFile("priv.key", trimmed, 0644)
}

func pad(str []byte) ([]byte) {
	stringLength := len(str)
	modulo := stringLength % 32
	toAppend := make([]byte, 32 - modulo)
	return append(str, toAppend...)
}
