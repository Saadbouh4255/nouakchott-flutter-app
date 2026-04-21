import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlaceSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search for places by name or description.'),
      );
    }

    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse('http://localhost:3000/api/places')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data?.statusCode != 200) {
          return const Center(child: Text('Error occurred while searching.'));
        }

        final List<dynamic> places = json.decode(snapshot.data!.body);
        final searchQuery = query.toLowerCase();

        final filteredDocs = places.where((doc) {
          final name = (doc['name'] ?? '').toString().toLowerCase();
          final description = (doc['description'] ?? '').toString().toLowerCase();
          
          return name.contains(searchQuery) || description.contains(searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No matching places found.'));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final data = filteredDocs[index];
            final name = data['name'] ?? 'Unnamed';
            final description = data['description'] ?? '';
            final imageUrl = data['imageUrl'] ?? '';
            final category = data['category'] ?? 'Uncategorized';

            return ListTile(
              leading: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
              title: Text(name),
              subtitle: Text(
                '$category\n$description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
