package apperrors

import (
	"net/http"
	"testing"
)

func TestCreateAPIError(t *testing.T) {
	expectedStatus := http.StatusInternalServerError
	expectedMessage := "custom error"
	apierr := CreateAPIError(expectedStatus, expectedMessage)

	if apierr.StatusCode != expectedStatus {
		t.Errorf("Test failed. Expected status %d, got %d", expectedStatus, apierr.StatusCode)
	}

	if apierr.Message != expectedMessage {
		t.Errorf("Test failed. Expected message %s, got %s", expectedMessage, apierr.Message)
	}

	if apierr.CausedBy != nil {
		t.Errorf("Caused by expected to be nil. Got %s instead", *apierr.CausedBy)
	}
}

func TestCreateAPIErrorWithCause(t *testing.T) {
	expectedStatus := http.StatusNotFound
	expectedMessage := "custom error"
	expectedCausedBy := "caused by error"
	apierr := CreateAPIErrorWithCause(expectedStatus, expectedMessage, expectedCausedBy)

	if apierr.StatusCode != expectedStatus {
		t.Errorf("Test failed. Expected status %d, got %d", expectedStatus, apierr.StatusCode)
	}

	if apierr.Message != expectedMessage {
		t.Errorf("Test failed. Expected message %s, got %s", expectedMessage, apierr.Message)
	}

	if *apierr.CausedBy != expectedCausedBy {
		t.Errorf("Test failed. Expected caused by %s, got %s", expectedCausedBy, *apierr.CausedBy)
	}
}

func TestCreateInternalServerError(t *testing.T) {
	expectedStatus := http.StatusInternalServerError
	expectedMessage := "custom error"
	expectedCausedBy := "caused by error"
	apierr := CreateInternalServerError(expectedMessage, expectedCausedBy)

	if apierr.StatusCode != expectedStatus {
		t.Errorf("Test failed. Expected status %d, got %d", expectedStatus, apierr.StatusCode)
	}

	if apierr.Message != expectedMessage {
		t.Errorf("Test failed. Expected message %s, got %s", expectedMessage, apierr.Message)
	}

	if *apierr.CausedBy != expectedCausedBy {
		t.Errorf("Test failed. Expected caused by %s, got %s", expectedCausedBy, *apierr.CausedBy)
	}
}

func TestApiErrorMessage(t *testing.T) {
	expectedStatus := http.StatusNotFound
	expectedMessage := "custom error"
	expectedCausedBy := "caused by error"
	apierr := CreateAPIErrorWithCause(expectedStatus, expectedMessage, expectedCausedBy)

	expectedErrorMessage := expectedMessage + " - caused by: " + expectedCausedBy
	if apierr.Error() != expectedErrorMessage {
		t.Errorf("Test failed. Error message expected: %s, got: %s", expectedErrorMessage, apierr.Error())
	}
}
