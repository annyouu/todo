package main

import (
	"net/http"
	"sync"

	"github.com/gin-gonic/gin"
)

type Todo struct {
	ID    int    `json:"id"`
	Title string `json:"title"`
	Done  bool   `json:"done"`
}

var (
	todos  []Todo
	nextID = 1
	mu     sync.Mutex
)

func main() {
	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	r.GET("/todos", func(c *gin.Context) {
		mu.Lock()
		defer mu.Unlock()
		c.JSON(http.StatusOK, todos)
	})

	r.POST("/todos", func(c *gin.Context) {
		var input struct {
			Title string `json:"title" binding:"required"`
		}
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		mu.Lock()
		defer mu.Unlock()
		todo := Todo{ID: nextID, Title: input.Title, Done: false}
		nextID++
		todos = append(todos, todo)
		c.JSON(http.StatusCreated, todo)
	})

	r.DELETE("/todos/:id", func(c *gin.Context) {
		var uri struct {
			ID int `uri:"id" binding:"required"`
		}
		if err := c.ShouldBindUri(&uri); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		mu.Lock()
		defer mu.Unlock()
		for i, t := range todos {
			if t.ID == uri.ID {
				todos = append(todos[:i], todos[i+1:]...)
				c.Status(http.StatusNoContent)
				return
			}
		}
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
	})

	r.Run(":8080")
}
