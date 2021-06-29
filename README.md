# Movio Case Study
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

As an offline customer
I want the app to show the latest saved version of the suggested movies feed
So I can always enjoy the suggested movies

#### Scenarios (Acceptance criteria)

```
Given the customer doesn't have connectivity
And there’s a cached version of the feed
When the customer requests to see the feed
Then the app should display the latest feed saved

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

### Load Suggested Movies Feed Fallback (Cache) Use Case

#### Data:
- No input

#### Primary course (happy path):
1. Execute "Load Suggested Movies Feed" command with above data.
2. System fetches feed data from cache.
3. System creates feed items from cached data.
4. System delivers feed items.

#### No cache course (sad path):
1. System delivers no feed items.

#### No connectivity – error course (sad path):
1. System delivers error.

---

### Save Suggested Movies Feed Use Case

#### Data:
- Suggested Movies

#### Primary course (happy path):
1. Execute "Save Feed Items" command with above data.
2. System encodes feed items.
3. System timestamps the new cache.
4. System replaces the cache with new data.
5. System delivers a success message.

#### Invalid data – error course (sad path):
1. System delivers error.

#### No connectivity – error course (sad path):
1. System delivers error.











