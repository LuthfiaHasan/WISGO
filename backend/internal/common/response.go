package common

import (
	"github.com/gin-gonic/gin"
)

// ResponseStandar format JSON baku proyek WISGO sesuai GEMINI.md
type ResponseStandar struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Success mengirim respon JSON sukses standar
func Success(c *gin.Context, httpCode int, message string, data interface{}) {
	c.JSON(httpCode, ResponseStandar{
		Status:  "success",
		Message: message,
		Data:    data,
	})
}

// Error mengirim respon JSON error standar
func Error(c *gin.Context, httpCode int, message string, errDetail ...interface{}) {
	var data interface{}
	if len(errDetail) > 0 {
		data = errDetail[0]
	}

	c.JSON(httpCode, ResponseStandar{
		Status:  "error",
		Message: message,
		Data:    data,
	})
}

