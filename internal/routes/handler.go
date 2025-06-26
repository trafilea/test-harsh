package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func Ping(c *gin.Context) {
	c.Data(http.StatusOK, "application/json; charset=utf-8", []byte("pong"))
}
