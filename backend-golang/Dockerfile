FROM golang:1.25-alpine AS build

# 빌드에 필요한 도구 설치
RUN apk add --no-cache git

WORKDIR /app

# 의존성 캐싱
COPY go.mod go.sum ./
RUN go mod download

# 소스 복사 및 빌드
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server ./cmd/server

FROM alpine:latest

# 보안 및 필수 패키지
RUN apk --no-cache add ca-certificates tzdata
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# 빌드된 바이너리 복사
COPY --from=build /app/server .

# 권한 설정
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8081

CMD ["./server"]