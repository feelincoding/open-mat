package main

import (
	"log"

	"github.com/feelincoding/backend-golang/open-mat/internal/config"
	"github.com/feelincoding/backend-golang/open-mat/internal/database"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// 환경변수 로드 (.env 파일)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// 설정 로드
	cfg := config.Load()

	// 로거 설정
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	// DB 연결
	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	log.Println("Database connected successfully")

	// Gin 라우터
	r := gin.Default()

	// CORS 설정 (나중에 미들웨어로 분리)
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "open-mat-golang",
			"version": "0.0.1",
		})
	})

	// API 라우트
	api := r.Group("/api")
	{
		// TODO: 오픈매트 라우트 등록
		api.GET("/open-mats", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "Open mats endpoint"})
		})
	}

	// 서버 시작
	port := cfg.Port
	if port == "" {
		port = "8081"
	}
	log.Printf("Server starting on :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
