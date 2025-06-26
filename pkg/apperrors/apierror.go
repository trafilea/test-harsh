package apperrors

import (
	"fmt"
	"net/http"
)

type APIError struct {
	StatusCode int     `json:"status_code"`
	Message    string  `json:"message"`
	CausedBy   *string `json:"caused_by"`
}

func CreateAPIError(statusCode int, message string) APIError {
	return APIError{
		StatusCode: statusCode,
		Message:    message,
	}
}

func CreateAPIErrorWithCause(statusCode int, message, causedBy string) APIError {
	return APIError{
		StatusCode: statusCode,
		Message:    message,
		CausedBy:   &causedBy,
	}
}

func CreateInternalServerError(message, causedBy string) APIError {
	return APIError{
		StatusCode: http.StatusInternalServerError,
		Message:    message,
		CausedBy:   &causedBy,
	}
}

func (e APIError) Error() string {
	errorMessage := e.Message

	if e.CausedBy != nil {
		errorMessage = fmt.Sprintf("%s - caused by: %s", errorMessage, *e.CausedBy)
	}

	return errorMessage
}
