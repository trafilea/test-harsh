package routes

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/trafilea/go-template/pkg/apperrors"
)

func TestPing(t *testing.T) {
	server := httptest.NewServer(InitializeRouter())
	defer server.Close()

	resp, err := http.Get(fmt.Sprintf("%s/api/ping", server.URL))

	if err != nil {
		t.Errorf("Test shouldnt have failed")
	}

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Test failed. Status code expected %d, got %d", http.StatusOK, resp.StatusCode)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		t.Errorf("Error reading body")
	}

	if string(body) != "pong" {
		t.Errorf("Test failed. Message in body expected %s, got %s", "pong", string(body))
	}
}

func TestNotFound(t *testing.T) {
	server := httptest.NewServer(InitializeRouter())
	defer server.Close()

	resp, err := http.Get(fmt.Sprintf("%s/api/resource-not-found/", server.URL))

	if err != nil {
		t.Errorf("Test shouldnt have failed")
	}

	if resp.StatusCode != http.StatusNotFound {
		t.Errorf("Test failed. Status code expected %d, got %d", http.StatusNotFound, resp.StatusCode)
	}
}

func TestAbortWithError(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	abortWithError(c, errors.New("custom error"))

	codeExpected := 500
	if codeExpected != w.Code {
		t.Errorf("Test failed. Expected '%d', got '%d'", codeExpected, w.Code)
	}

	var response apperrors.APIError
	json.Unmarshal(w.Body.Bytes(), &response)

	msgExpected := "custom error"
	if response.Message != msgExpected {
		t.Errorf("Test failed. Expected '%s', got '%s'", msgExpected, response.Message)
	}

	if response.CausedBy != nil {
		t.Errorf("Test failed. Expected response.CausedBy to be nil")
	}
}

func TestAbortWithCustomError(t *testing.T) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	abortWithCustomError(c, http.StatusInternalServerError, apperrors.CreateAPIErrorWithCause(http.StatusBadRequest, "custom error", "custom caused by"))

	codeExpected := 400
	if codeExpected != w.Code {
		t.Errorf("Test failed. Expected '%d', got '%d'", codeExpected, w.Code)
	}

	var response apperrors.APIError
	json.Unmarshal(w.Body.Bytes(), &response)

	msgExpected := "custom error"
	if response.Message != msgExpected {
		t.Errorf("Test failed. Message expected '%s', got '%s'", msgExpected, response.Message)
	}

	causedByExpected := "custom caused by"
	if *response.CausedBy != causedByExpected {
		t.Errorf("Test failed. Caused by expected '%s', got '%s'", causedByExpected, *response.CausedBy)
	}
}
