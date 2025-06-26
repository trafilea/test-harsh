package routes

import (
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestPingOK(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	Ping(c)

	codeWant := 200
	if codeWant != w.Code {
		t.Errorf("Test failed. Expected '%d', got '%d'", codeWant, w.Code)
	}

	got := w.Body.String()
	want := "pong"
	if got != want {
		t.Errorf("Test failed. Expected '%s', got '%s'", want, got)
	}
}
