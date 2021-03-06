[![CI](https://github.com/danstorre/Movio_2.0/actions/workflows/CI.yml/badge.svg)](https://github.com/danstorre/Movio_2.0/actions/workflows/CI.yml)

# Movio
Search for trending movies by using this app.

## Suggested Movies Feed Feature Specs

### Story: Customer requests to see their suggested movies feed

### Narrative #1

As an online customer 
I want the app to automatically load movies suggestions 
So I can always enjoy the newest movies in the market.

#### Scenarios (Acceptance criteria)

```
Given the customer has connectivity 
When the customer requests to see movie suggestions
Then the app should display the latest feed from suggested movies
And replace the cache with the new feed
```

### Narrative #2

```
As an offline customer
I want the app to show the latest saved version of the suggested movies feed
So I can always enjoy the suggested movies
```

#### Scenarios (Acceptance criteria)

```
Given the customer doesn't have connectivity
And there’s a cached version of the feed
And the cache is less than seven days old
When the customer requests to see the feed
Then the app should display the latest feed saved

Given the customer doesn't have connectivity
And there’s a cached version of the feed
And the cache is more than seven days old
When the customer requests to see the feed
Then the app should display an error message

Given the customer doesn't have connectivity
And the cache is empty
When the customer requests to see the feed
Then the app should display an error message
```

## Use Cases

### Load Feed From Remote Use Case

#### Data:
- URL

#### Primary course (happy path):
1. Execute "Load Suggested Movies Feed” command with above data.
2. System downloads data from the URL.
3. System validates downloaded data.
4. System creates feed suggested movies from valid data.
5. System delivers feed suggested movies.

#### Invalid data – error course (sad path):
1. System delivers error.

#### No connectivity – error course (sad path):
1. System delivers error.

---

### Load Cache from Suggested Movies Use Case

#### Data:
- No input

#### Primary course (happy path):
1. Execute "Load Suggested Movies Feed" command with above data.
2. System fetches feed data from cache.
3. System validates the cache is less than seven days old.
4. System creates feed suggested movies from cached data.
5. System delivers feed suggested movies.

### Error course course (sad path):
1. System delivers error.

### Expired cache course (sad path):
1. System deletes cache.
2. System delivers no feed suggested movies.

#### No cache course (sad path):
1. System delivers no feed suggested movies.

---

### Cache Suggested Movies Use Case

#### Data:
- Suggested Movies

#### Primary course (happy path):
1. Execute "Save Feed suggested movies" command with above data.
2. System deletes old cache.
3. System encodes feed suggested movies.
4. System timestamps the new cache.
5. System saves new cache.
6. System delivers a success message.

#### Saving error course (sad path):
1. System delivers error.

#### Deletion error course (sad path):
1. System delivers error.

---

## Flowchart

![Suggested Movies Feed - Flow Chart](https://user-images.githubusercontent.com/12664335/123861612-c4804c00-d8fd-11eb-8404-b6e43fc69272.png)

## Model Specs

### Movie

| Property          | Type                    |
|-------------------|-------------------------|
| `id`              | `UUID`                  |
| `title` 	    | `String`		      |
| `plot`	    | `String` 		      | 
| `poster` 	    | `URL` (optional) 		      |


### Payload contract

```
GET /discover/movie

2xx RESPONSE

{
	"results": [
		{
			"poster_path": null,
			"overview": "Go behind the scenes during One Directions sell out \"Take Me Home\" tour and experience life on the road.",
			"id": 164558,
			"title": "One Direction: This Is Us",
		},
		{
			"poster_path": null,
			"overview": "",
			"id": 654,
			"title": "On the Waterfront"
		},
		...
	]
}
```
---

## Architecture

![Suggested Movies Feed - Architecture Specs](https://user-images.githubusercontent.com/12664335/123861728-e4177480-d8fd-11eb-928c-2cb292e7af68.png)






