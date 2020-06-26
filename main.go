package main

import (
	"fmt"
	"html/template"
	"log"
	"math"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/xanzy/go-gitlab"
)

var (
	gitLabAddr         string
	gitLabToken        string
	gitLabGroup        string
	gitLabGroupData    *gitlab.Group
	client             *gitlab.Client
	gitLabGroupMembers []*gitlab.GroupMember
)

type pageInfo struct {
	Group   gitlab.Group
	OpenMRs *filteredMRs
}

type filteredMRs struct {
	Fresh []*gitlab.MergeRequest
	Stale []*gitlab.MergeRequest
}

func checkEnv(e string) (string, error) {
	v := os.Getenv(e)
	if v == "" {
		return "", fmt.Errorf("ERR: environment varaible %s is empty", e)
	}

	return v, nil
}

func getGroupMembers(group string) []*gitlab.GroupMember {
	// TODO: Handle resp and err
	allMembers, _, _ := client.Groups.ListGroupMembers(group, &gitlab.ListGroupMembersOptions{})

	// Filter unwanted users
	for _, v := range allMembers {
		if v.State == "active" && v.Username != "root" && !strings.Contains(strings.ToLower(v.Username), "bot") {
			gitLabGroupMembers = append(gitLabGroupMembers, v)
		}
	}

	return gitLabGroupMembers
}

func getFilteredMergeRequests(members []*gitlab.GroupMember) *filteredMRs {
	now := time.Now()
	groupMergeReqs := []*gitlab.MergeRequest{}
	targetState := "opened"
	scope := "all"
	for _, v := range members {
		// TODO: Handle resp and err
		mrs, _, _ := client.MergeRequests.ListMergeRequests(&gitlab.ListMergeRequestsOptions{
			AuthorID: &v.ID,
			State:    &targetState,
			Scope:    &scope,
		})
		groupMergeReqs = append(groupMergeReqs, mrs...)
	}

	// Filter out fresh MRs from stale ones
	freshMergeReqs := []*gitlab.MergeRequest{}
	staleMergeReqs := []*gitlab.MergeRequest{}
	for _, v := range groupMergeReqs {
		diff := math.Round(now.Sub(*v.CreatedAt).Hours() / 24)
		if diff < 14 {
			freshMergeReqs = append(freshMergeReqs, v)
		} else {
			staleMergeReqs = append(staleMergeReqs, v)
		}
	}

	// Sort the MRs by creation date: oldest first
	sort.Slice(freshMergeReqs, func(i, j int) bool { return freshMergeReqs[i].CreatedAt.Before(*freshMergeReqs[j].CreatedAt) })
	sort.Slice(staleMergeReqs, func(i, j int) bool { return staleMergeReqs[i].CreatedAt.Before(*staleMergeReqs[j].CreatedAt) })

	return &filteredMRs{
		Fresh: freshMergeReqs,
		Stale: staleMergeReqs,
	}
}

func trimWIP(str string) string {
	return strings.TrimPrefix(str, "WIP: ")
}

func deriveReference(str string) string {
	chopped := strings.Split(str, "/")
	return fmt.Sprintf("%s !%s", strings.Join(chopped[3:(len(chopped)-2)], "/"), chopped[len(chopped)-1])
}

func homePage(w http.ResponseWriter, r *http.Request) {
	fMRs := getFilteredMergeRequests(gitLabGroupMembers)
	info := pageInfo{
		Group:   *gitLabGroupData,
		OpenMRs: fMRs,
	}

	t := template.Must(template.New("index.html.tpl").Funcs(template.FuncMap{
		"trimWIP":         trimWIP,
		"deriveReference": deriveReference,
	}).ParseFiles("templates/index.html.tpl"))

	if err := t.Execute(w, info); err != nil {
		log.Print("template execution error: ", err)
	}
}

func healthz(w http.ResponseWriter, _ *http.Request) {
	w.WriteHeader(http.StatusOK)
}

func init() {
	var err error
	// TODO: Handle URL parsing (needs to end in '/')
	gitLabAddr = os.Getenv("GITLAB_ADDR")

	gitLabToken, err = checkEnv("GITLAB_TOKEN")
	if err != nil {
		log.Fatal(err)
	}

	gitLabGroup, err = checkEnv("GITLAB_GROUP")
	if err != nil {
		log.Fatal(err)
	}

	client = gitlab.NewClient(nil, gitLabToken)
	if gitLabAddr != "" {
		if err := client.SetBaseURL(gitLabAddr); err != nil {
			log.Fatal(err)
		}
	}
}

func main() {
	// TODO: Handle resp and err
	gitLabGroupData, _, _ = client.Groups.GetGroup(gitLabGroup)
	gitLabGroupMembers = getGroupMembers(gitLabGroup)
	http.HandleFunc("/", homePage)
	http.HandleFunc("/healthz", healthz)

	// static content
	fs := http.FileServer(http.Dir("./templates"))
	http.Handle("/favicon.ico", fs)
	http.Handle("/favicon-16x16.png", fs)
	http.Handle("/favicon-32x32.png", fs)

	log.Fatal(http.ListenAndServe(":8080", nil))
}
