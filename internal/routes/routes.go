package routes

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/trafilea/go-template/pkg/apperrors"
)

func InitializeRouter() *gin.Engine {
	router := gin.Default()

	router.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, apperrors.CreateAPIError(http.StatusNotFound, "resource not found"))
	})

	api := router.Group("/api")

	api.GET("/ping", Ping)

	return router
}

func abortWithCustomError(c *gin.Context, defaultStatus int, err error) {
	status := defaultStatus
	if apiError, ok := err.(apperrors.APIError); ok && apiError.StatusCode != 0 {
		c.AbortWithStatusJSON(apiError.StatusCode, apiError)
		status = apiError.StatusCode
	} else {
		c.AbortWithStatusJSON(defaultStatus, apperrors.CreateAPIError(defaultStatus, err.Error()))
	}

	fmt.Printf("[ERROR] - [status:%d]%s \n", status, err.Error())
}

func abortWithError(c *gin.Context, err error) {
	abortWithCustomError(c, http.StatusInternalServerError, err)
}
