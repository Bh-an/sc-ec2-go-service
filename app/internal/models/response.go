package models

type APIResponse struct {
	Message string `json:"message"`
}

type VersionResponse struct {
	Version   string `json:"version"`
	GitCommit string `json:"gitCommit"`
	BuildDate string `json:"buildDate"`
}
